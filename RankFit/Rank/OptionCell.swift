//
//  OptionCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/03.
//

import UIKit

class OptionCell: UICollectionViewCell {
    
    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var score: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        contentView.backgroundColor = UIColor.separator
        contentView.layer.cornerRadius = 20
    }
    
    func config(info: receiveRankInfo) {
        if info.Nickname == "나의 랭킹" { // 맨 처음 나의 랭킹만 예외로 적용
            contentView.backgroundColor = .cyan
            profile.layer.isHidden = true
            nickName.layer.isHidden = true
            rank.text = info.Nickname
            score.text = info.Score
        } else {
            contentView.backgroundColor = .orange
            profile.layer.isHidden = false
            nickName.layer.isHidden = false
            rank.text = info.Ranking
            nickName.text = info.Nickname
            score.text = info.Score
        }
    }
}
