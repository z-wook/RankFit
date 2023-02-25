//
//  MyDiaryCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/20.
//

import UIKit

class MyDiaryCell: UICollectionViewCell {
    
    @IBOutlet weak var ImageView: UIImageView!
    @IBOutlet weak var frontView: UIView!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func config(Image: UIImage) {
        frontView.backgroundColor = .white.withAlphaComponent(0.6)
        frontView.layer.isHidden = true
        ImageView.image = Image
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                frontView.isHidden = false
            } else {
                frontView.isHidden = true
            }
        }
    }
}
