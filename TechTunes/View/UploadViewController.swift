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

class UploadViewController: UIViewController {
    
    
    
    
    @IBOutlet var titleTextField: UITextField!
    
    @IBOutlet var detailTextField: UITextField!
    
    @IBOutlet var filePathText: UILabel!
    
    @IBOutlet var coverArtImageView: UIImageView!
    
    var musicFilePath = ""
    
    var coverArt: UIImage = UIImage()
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func upload() {
        guard !musicFilePath.isEmpty, coverArt != UIImage(), let title = titleTextField.text, !title.isEmpty, let detail = detailTextField.text, !detail.isEmpty else {
            print("Please provide a title, detail, music file, and cover art.")
            return
        }
        
        // Upload both the music file and cover art
        uploadMusicFile { [weak self] musicURL in
            guard let self = self else { return }
            self.uploadCoverArt { coverArtURL in
                // Store the metadata in Firestore after both files are uploaded
                self.saveMusicDataToFirestore(musicURL: musicURL, coverArtURL: coverArtURL, title: title, detail: detail)
            }
        }
    }
    
    @IBAction func MusicfileRead() {
        //選択できるファイルを.mp3に限定
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.mp3
            ],
            asCopy: true)
        picker.delegate = self
        self.navigationController?.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func coverArtRead() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadMusicFile(completion: @escaping (String) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let musicRef = storageRef.child("music/\(UUID().uuidString).mp3")
        
        if let musicUrl = URL(string: musicFilePath) {
            musicRef.putFile(from: musicUrl, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading music file: \(error.localizedDescription)")
                    return
                }
                
                musicRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting music file URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let downloadURL = url {
                        print("Music file uploaded successfully: \(downloadURL)")
                        completion(downloadURL.absoluteString) // Pass URL to completion handler
                    }
                }
            }
        }
    }
    
    func uploadCoverArt(completion: @escaping (String) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let coverArtRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        if let imageData = coverArt.jpegData(compressionQuality: 0.8) {
            coverArtRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading cover art: \(error.localizedDescription)")
                    return
                }
                
                coverArtRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting cover art URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let downloadURL = url {
                        print("Cover art uploaded successfully: \(downloadURL)")
                        completion(downloadURL.absoluteString) // Pass URL to completion handler
                    }
                }
            }
        }
    }
    
    func saveMusicDataToFirestore(musicURL: String, coverArtURL: String, title: String, detail: String) {
        // Create a document in the "Musics" collection with the uploaded data
        let musicData: [String: Any] = [
            "title": title,
            "detail": detail,
            "musicURL": musicURL,
            "coverArt": coverArtURL
        ]
        
        db.collection("Musics").addDocument(data: musicData) { error in
            if let error = error {
                print("Error saving music data to Firestore: \(error.localizedDescription)")
            } else {
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
            filePathText.text = filePath
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("キャンセル")
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
                    }
                }
            }
        }
    }
}
