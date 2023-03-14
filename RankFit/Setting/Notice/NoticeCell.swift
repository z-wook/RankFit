//
//  NoticeCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/26.
//

import UIKit

class NoticeCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    func configure(info: notification) {
        titleLabel.text = info.title
        dateLabel.text = info.register_day
    }
}
