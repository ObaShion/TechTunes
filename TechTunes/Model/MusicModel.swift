//
//  MusicModel.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/11.
//

import Foundation

class Music {
    var musicURL: String
    var title: String
    var detail: String
    
    init(musicURL: String, title: String, detail: String) {
        self.musicURL = musicURL
        self.title = title
        self.detail = detail
    }
}
