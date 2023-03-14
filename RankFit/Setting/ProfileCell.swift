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
        
        profileImage.layer.cornerRadius = 20
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configCell() {
        guard let nick_name = saveUserData.getKeychainStringValue(forKey: .NickName) else {
            nickName.text = "로그인이 필요합니다."
            nickName.adjustsFontSizeToFitWidth = true
            profileImage.image = UIImage(systemName: "person.fill")
            return
        }
        nickName.text = nick_name
        let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg")
        guard let image = image else {
            profileImage.image = UIImage(systemName: "person.fill")
            return
        }
        profileImage.image = image
    }
}
