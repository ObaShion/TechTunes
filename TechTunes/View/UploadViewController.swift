//
//  UploadViewController.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/12.
//

import UIKit
import UniformTypeIdentifiers
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import Gifu

class UploadViewController: UIViewController {
    
    @IBOutlet var titleTextField: UITextField!
    
    @IBOutlet var detailTextField: UITextField!
    
    //    @IBOutlet var filePathText: UILabel!
    
    @IBOutlet var coverArtImageView: UIImageView!
    
    @IBOutlet var photoSelectButton: UIButton!
    
    var musicFilePath = ""
    
    var coverArt: UIImage = UIImage()
    
    let db = Firestore.firestore()
    
    var uploadAlert: UIAlertController?
    
    var uploadTask: StorageUploadTask?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let alert = UIAlertController(title: "使い方", message: "mp3ファイルを選択してくさい", preferredStyle: UIAlertController.Style.alert)
        
        //        let height = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400)
        //        alert.view.addConstraint(height)
        //
        //        let imageView = UIImageView(frame: CGRect(x: 10, y: 70, width: 250, height: 250))
        //
        //        imageView.image = UIImage(named: "demo")
        //
        //        imageView.contentMode = .scaleAspectFit
        //
        //        alert.view.addSubview(imageView)
        
        alert.addAction( UIAlertAction(title: "選択する", style: UIAlertAction.Style.default, handler: { UIAlertAction in
            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [
                    UTType.mp3
                ],
                asCopy: true)
            picker.delegate = self
            self.navigationController?.present(picker, animated: true, completion: nil)
            
        }))
        
        present(alert, animated: true)
        
        
        photoSelectButton.layer.cornerRadius = 25
        
    }
    
    func dismissUploadAlert() {
        self.uploadAlert?.dismiss(animated: true, completion: {
            self.uploadAlert = nil // Clear the alert reference
        })
    }
    
    //キーボード閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func upload() {
        
        
        guard !musicFilePath.isEmpty, coverArt != UIImage(), let title = titleTextField.text, !title.isEmpty, let detail = detailTextField.text, !detail.isEmpty else {
            let alert = UIAlertController(title: "未入力", message: "曲名,コメントを入力してください", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
            present(alert, animated: true)
            print("Please provide a title, detail, music file, and cover art.")
            return
        }
        
        uploadAlert = UIAlertController(title: "アップロード中...", message: "\n\n", preferredStyle: .alert)
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
        uploadAlert?.view.addSubview(progressView)
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            self.uploadTask?.cancel() // Cancel the upload if the user presses cancel
        }
        uploadAlert?.addAction(cancelAction)
        
        self.present(uploadAlert!, animated: true) {
            progressView.setProgress(0.0, animated: true) // Start progress at 0
        }
        
        uploadMusicFile(progressView: progressView) { [weak self] musicURL in
            guard let self = self else { return }
            self.uploadCoverArt(progressView: progressView) { coverArtURL in
                // Store the metadata in Firestore after both files are uploaded
                self.saveMusicDataToFirestore(musicURL: musicURL, coverArtURL: coverArtURL, title: title, detail: detail)
            }
        }
    }
    
    //    @IBAction func MusicfileRead() {
    //        //選択できるファイルを.mp3に限定
    //        let picker = UIDocumentPickerViewController(
    //            forOpeningContentTypes: [
    //                UTType.mp3
    //            ],
    //            asCopy: true)
    //        picker.delegate = self
    //        self.navigationController?.present(picker, animated: true, completion: nil)
    //    }
    
    @IBAction func coverArtRead() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadMusicFile(progressView: UIProgressView, completion: @escaping (String) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let musicRef = storageRef.child("music/\(UUID().uuidString).mp3")
        
        if let musicUrl = URL(string: musicFilePath) {
            uploadTask = musicRef.putFile(from: musicUrl, metadata: nil)
            
            uploadTask?.observe(.progress) { snapshot in
                let percentComplete = Double(snapshot.progress?.fractionCompleted ?? 0)
                progressView.setProgress(Float(percentComplete), animated: true)
                print("Music upload progress: \(percentComplete * 100)%")
            }
            
            uploadTask?.observe(.success) { snapshot in
                musicRef.downloadURL { url, error in
                    if let error = error {
                        self.dismissUploadAlert()
                        print("Error getting music file URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let downloadURL = url {
                        print("Music file uploaded successfully: \(downloadURL)")
                        completion(downloadURL.absoluteString)
                    }
                }
            }
            
            uploadTask?.observe(.failure) { snapshot in
                self.dismissUploadAlert()
                if let error = snapshot.error {
                    print("Error uploading music file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func uploadCoverArt(progressView: UIProgressView, completion: @escaping (String) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let coverArtRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        if let imageData = coverArt.jpegData(compressionQuality: 0.8) {
            uploadTask = coverArtRef.putData(imageData, metadata: nil)
            
            uploadTask?.observe(.progress) { snapshot in
                let percentComplete = Double(snapshot.progress?.fractionCompleted ?? 0)
                progressView.setProgress(Float(percentComplete), animated: true)
                print("Cover art upload progress: \(percentComplete * 100)%")
            }
            
            uploadTask?.observe(.success) { snapshot in
                coverArtRef.downloadURL { url, error in
                    if let error = error {
                        self.dismissUploadAlert()
                        print("Error getting cover art URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let downloadURL = url {
                        print("Cover art uploaded successfully: \(downloadURL)")
                        completion(downloadURL.absoluteString)
                    }
                }
            }
            
            uploadTask?.observe(.failure) { snapshot in
                self.dismissUploadAlert()
                if let error = snapshot.error {
                    print("Error uploading cover art: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveMusicDataToFirestore(musicURL: String, coverArtURL: String, title: String, detail: String) {
        let musicData: [String: Any] = [
            "title": title,
            "detail": detail,
            "musicURL": musicURL,
            "coverArt": coverArtURL,
            "createdAt": Timestamp()
        ]
        
        db.collection("Musics").addDocument(data: musicData) { error in
            if let error = error {
                self.dismissUploadAlert()
                let alert = UIAlertController(title: "エラー", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                print("Error saving music data to Firestore: \(error.localizedDescription)")
            } else {
                self.dismissUploadAlert()
                let alert = UIAlertController(title: "アップロード完了", message: "音楽が正常に保存されました", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default,handler: { UIAlertAction in
                    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true)
                print("Music data saved to Firestore successfully")
            }
        }
    }
    
    
}

//曲ファイル選択
extension UploadViewController: UIDocumentPickerDelegate{
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let filePath = urls.first?.description {
            musicFilePath = filePath
            //            filePathText.text = filePath
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("キャンセル")
        let alert = UIAlertController(title: "エラー", message: "ファイルが選択されていません。", preferredStyle: UIAlertController.Style.alert)
        alert.addAction( UIAlertAction(title: "再選択する", style: UIAlertAction.Style.default, handler: { UIAlertAction in
            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [
                    UTType.mp3
                ],
                asCopy: true)
            picker.delegate = self
            self.navigationController?.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "中止する", style: UIAlertAction.Style.destructive,handler: { UIAlertAction in
            self.navigationController?.popViewController(animated: true)
        }))
        
        present(alert, animated: true)
    }
}

//カバーアート選択
extension UploadViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProvider = results.first?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    self.coverArt = image
                    DispatchQueue.main.async {
                        self.coverArtImageView.image = self.coverArt
                        //                        self.selectCoverArtImageView.image = UIImage(systemName: "checkmark.circle")
                        
                    }
                }
            }
        }
    }
}
