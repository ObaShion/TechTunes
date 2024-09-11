//
//  HomeViewController.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/11.
//

import UIKit

class HomeViewController: UIViewController {

    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var searchBar: UISearchBar!
    
    var musics: [Music] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        musics.append(Music(coverArtURL: "", musicURL: "", title: "テスト", detail: "テストソングです"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = musics[indexPath.row].title
        cell.detailTextLabel?.text = musics[indexPath.row].detail
        cell.imageView?.image = UIImage(systemName: "music.note")
        return cell
    }
}
