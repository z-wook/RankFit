//
//  QuickExPickerCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/02.
//

import UIKit

class QuickExPickerCell: UICollectionViewCell {
    
    @IBOutlet weak var exTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .systemOrange.withAlphaComponent(0.7)
        contentView.layer.cornerRadius = 20
//        self.layer.borderColor = CGColor(red: 0.7, green: 0.5, blue: 1, alpha: 1)
//        self.layer.borderWidth = 3
//        self.layer.cornerRadius = 20
    }
    
    func configure(info: ExerciseInfo) {
        exTitle.text = info.exerciseName
    }
}
