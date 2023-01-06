//
//  MyDetailCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/02.
//

import UIKit
import Combine

class MyDetailCell: UICollectionViewCell {
    
    @IBOutlet weak var rankImage: UIImageView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var score: UILabel!
    
    func config(rank: String, nickname: String, score: String) {
        self.rankImage.image = UIImage()
        self.rankLabel.text = rank
        self.nickName.text = nickname
        self.score.text = score
    }
}
