//
//  CategoryCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/17.
//

import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var categoryLabel: UILabel!
    var select: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 15
    }
    
    func configure(categoryName: String) {
        categoryLabel.text = categoryName
        if select {
            contentView.backgroundColor = .systemPink
        } else {
            contentView.backgroundColor = .systemCyan.withAlphaComponent(0.6)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = .systemPink
                select = true
            } else {
                contentView.backgroundColor = .systemCyan.withAlphaComponent(0.6)
                select = false
            }
        }
    }
}
