//
//  MusicModel.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/11.
//

import Foundation

class Music {
    var coverArtURL: String
    var musicURL: String
    var title: String
    var detail: String
    
    init(coverArtURL: String, musicURL: String, title: String, detail: String) {
        self.coverArtURL = coverArtURL
        self.musicURL = musicURL
        self.title = title
        self.detail = detail
    }
}
