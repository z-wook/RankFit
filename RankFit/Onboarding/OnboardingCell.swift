//
//  OnboardingCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/11.
//

import UIKit

class OnboardingCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbnailView.layer.cornerRadius = 10
    }
    
    func configure(message: OnboardingMessage) {
        thumbnailView.image = UIImage(named: message.imageName)
        titleLabel.text = message.title
        descriptionLabel.text = message.description
    }
}
