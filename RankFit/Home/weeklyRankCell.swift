//
//  weeklyRankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/25.
//

import UIKit

class weeklyRankCell: UICollectionViewCell {
    
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var exerciseLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 20
    }
    
    func configure(info: WeeklyRank) {
        rankLabel.text = info.rank + "위"
        exerciseLabel.text = info.exercise
    }
}
