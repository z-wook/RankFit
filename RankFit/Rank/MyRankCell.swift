//
//  RankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/28.
//

import UIKit

class MyRankCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rank: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        contentView.backgroundColor = UIColor.separator
        contentView.layer.cornerRadius = 20
    }
    
    func config(info: MyRankInfo) {
        titleLabel.text = info.Exercise
        if info.My_Ranking == "" {
            rank.text = ""
        } else {
            rank.text = info.My_Ranking + "위"
        }
    }
}
