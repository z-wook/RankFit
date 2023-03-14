//
//  weeklyRankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/25.
//

import UIKit

class weeklyRankCell: UICollectionViewCell {
    
    @IBOutlet weak var popularity: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 20
    }
    
    func configure(info: WeeklyRank) {
        if info.exercise == "" {
            popularity.text = info.rank
        } else {
            popularity.text = info.rank + " 순위 - " + info.exercise
        }
    }
}
