//
//  MyProfileCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/17.
//

import UIKit

class MyProfileCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var infomation: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    func configCell(title: String, infomation: String) {
        self.title.text = title
        self.infomation.text = infomation
    }
}
