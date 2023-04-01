//
//  ExerciseInfoCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit

class ExerciseInfoCell: UICollectionViewCell {
    
    @IBOutlet weak var exerciseLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        contentView.backgroundColor = .systemOrange
        contentView.backgroundColor = UIColor(named: "baseColor")
        contentView.layer.cornerRadius = 10
    }
    
    func configure(item: ExerciseInfo) {
        exerciseLabel.text = item.exerciseName
    }
}
