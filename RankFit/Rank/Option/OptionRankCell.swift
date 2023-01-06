//
//  OptionRankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/06.
//

import UIKit

class OptionRankCell: UICollectionViewCell {
    
    @IBOutlet weak var rankLabel: UILabel!
    
    func config(info: String) {
        rankLabel.text = info
    }
    
}
