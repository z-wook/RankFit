//
//  RankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/28.
//

import UIKit

class RankCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    func config(info: String) {
        titleLabel.text = info
    }
}
