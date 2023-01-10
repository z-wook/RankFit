//
//  MyProfileTableViewCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/16.
//

import UIKit

class ProfileCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nickName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        configCell()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configCell() {
        guard let nick_name = saveUserData.getKeychainStringValue(forKey: .NickName) else {
            nickName.text = "로그인이 필요합니다."
            return
        }
        nickName.text = nick_name
    }
}
