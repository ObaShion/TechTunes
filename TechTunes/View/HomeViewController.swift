//
//  HomeViewController.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/11.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import SDWebImage

class HomeViewController: UIViewController {
    
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var searchBar: UISearchBar!
    
    var musics: [Music] = []
        
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        //テストデータ
        //        musics.append(Music(coverArtURL: "https://steenz.jp/wp-content/uploads/2023/12/shion6.jpg", musicURL: "https://classical-sound.up.seesaa.net/image/Pachelbel-Canon-in-D-2019-AR.mp3", title: "カノン", detail: "AVPlayerのテスト中"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        musics = []
        fetch()
    }
    
    func fetch() {
        Task { @MainActor in
            do {
                let snapshot = try await db.collection("Musics").getDocuments()
                for document in snapshot.documents {
                    let documentData = document.data()
                    
                    if let coverArt = documentData["coverArt"] as? String,
                       let musicURL = documentData["musicURL"] as? String,
                       let title = documentData["title"] as? String,
                       let detail = documentData["detail"] as? String {
                        
                        let music = Music(coverArtURL: coverArt, musicURL: musicURL, title: title, detail: detail)
                        musics.append(music)
                        tableView.reloadData()
                    }
                }            } catch {
                    print("Error getting documents: \(error)")
                }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPlayerView" {
            let playerView = segue.destination as! PlayerViewController
            playerView.url = URL(string: musics[tableView.indexPathForSelectedRow!.row].musicURL)
            playerView.coverArtURL = musics[tableView.indexPathForSelectedRow!.row].coverArt
        }
    }
    
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let coverArtURL:URL = URL(string: musics[indexPath.row].coverArt)!
        cell.textLabel?.text = musics[indexPath.row].title
        cell.detailTextLabel?.text = musics[indexPath.row].detail
        cell.imageView?.sd_setImage(with: coverArtURL,placeholderImage: UIImage(systemName: "questionmark.circle"))
        cell.imageView?.contentMode = .scaleAspectFit
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
