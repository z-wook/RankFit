//
//  QuickSelectExCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/04.
//

import UIKit

class QuickSelectExCell: UICollectionViewCell {
    
    @IBOutlet weak var selectedEx: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .systemOrange.withAlphaComponent(0.8)
        contentView.layer.cornerRadius = 10
    }
    
    func configure(info: ExerciseInfo) {
        selectedEx.text = info.exerciseName
    }
}
