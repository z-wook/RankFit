//
//  DefaultCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/16.
//

import UIKit

class DefaultCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(image: UIImage? = nil, color: UIColor? = nil, title: String, description: String? = nil) {
        imgView.image = image
        imgView.tintColor = color
        titleLabel.text = title
        stateLabel.text = description
    }
}
