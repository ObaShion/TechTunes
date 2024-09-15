//
//  MusicTableViewCell.swift
//  TechTunes
//
//  Created by 大場史温 on 2024/09/15.
//

import UIKit

class MusicTableViewCell: UITableViewCell {

    @IBOutlet var coverArtImageView: UIImageView!
    
    @IBOutlet var titleText: UILabel!
    
    @IBOutlet var detailText: UILabel!
    
    static let height: CGFloat = 60
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
