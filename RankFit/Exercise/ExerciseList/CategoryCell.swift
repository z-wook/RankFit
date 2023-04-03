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
            contentView.backgroundColor = .systemPink.withAlphaComponent(0.8)
            categoryLabel.textColor = .white
        } else {
            contentView.backgroundColor = UIColor(named: "category")
            categoryLabel.textColor = .black
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = .systemPink.withAlphaComponent(0.8)
                categoryLabel.textColor = .white
                select = true
            } else {
                contentView.backgroundColor = UIColor(named: "category")
                categoryLabel.textColor = .black
                select = false
            }
        }
    }
}
