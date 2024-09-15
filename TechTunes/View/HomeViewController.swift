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
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        
        tableView.delegate = self
        
        tableView.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(HomeViewController.refresh(sender:)), for: .valueChanged)
        
        tableView.register(UINib(nibName: "MusicTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        searchBar.delegate = self
        
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
        
        
        //テストデータ
        //        musics.append(Music(coverArtURL: "https://steenz.jp/wp-content/uploads/2023/12/shion6.jpg", musicURL: "https://classical-sound.up.seesaa.net/image/Pachelbel-Canon-in-D-2019-AR.mp3", title: "カノン", detail: "AVPlayerのテスト中"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        musics = []
        fetch()
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        musics = []
        fetch()
        refreshControl.endRefreshing()
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func fetch() {
        Task { @MainActor in
            do {
                let snapshot = try await db.collection("Musics").order(by: "createdAt", descending: true).getDocuments()
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
    
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == "toPlayerView" {
    //            let playerView = segue.destination as! PlayerViewController
    //            playerView.url = URL(string: musics[tableView.indexPathForSelectedRow!.row].musicURL)
    //            playerView.coverArtURL = musics[tableView.indexPathForSelectedRow!.row].coverArt
    //        }
    //    }
    
    
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MusicTableViewCell
        let coverArtURL:URL = URL(string: musics[indexPath.row].coverArt)!
        cell.titleText.text = musics[indexPath.row].title
        cell.detailText.text = musics[indexPath.row].detail
        cell.coverArtImageView.sd_setImage(with: coverArtURL,placeholderImage: UIImage(systemName: "questionmark.circle"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard: UIStoryboard = self.storyboard!
        let playerView = storyboard.instantiateViewController(withIdentifier: "playerView") as! PlayerViewController
        
        let selectedMusic = musics[indexPath.row]
        playerView.url = URL(string: selectedMusic.musicURL)
        playerView.coverArtURL = selectedMusic.coverArt
        playerView.titleText = selectedMusic.title
        
        self.present(playerView, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MusicTableViewCell.height
    }
}


extension HomeViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        Task { @MainActor in
            do {
                let snapshot = try await db.collection("Musics").whereField("title", isGreaterThanOrEqualTo: searchBar.text ?? "").whereField("title", isLessThanOrEqualTo: (searchBar.text ?? "") + "\u{f8ff}").getDocuments()
                for document in snapshot.documents {
                    let documentData = document.data()
                    
                    if let coverArt = documentData["coverArt"] as? String,
                       let musicURL = documentData["musicURL"] as? String,
                       let title = documentData["title"] as? String,
                       let detail = documentData["detail"] as? String {
                        
                        let music = Music(coverArtURL: coverArt, musicURL: musicURL, title: title, detail: detail)
                        musics.removeAll()
                        musics.append(music)
                        tableView.reloadData()
                    }
                }            } catch {
                    print("Error getting documents: \(error)")
                }
        }
    }
}
