//
//  MyProfileCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/17.
//

import UIKit

class MyProfileCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var information: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func configCell(title: String, information: String) {
        self.title.text = title
        
        switch title {
        case "이메일": self.information.text = information
            
        case "성별":
            if information == "0" {
                self.information.text = "남성"
            } else if information == "1" {
                self.information.text = "여성"
            } else { return }
            
        case "나이":
            self.information.text = "만 " + information + "세"
            
        case "몸무게":
            self.information.text = information + "kg"
        
        case "닉네임":
            self.information.text = information
            
        case "프로필":
            self.information.text = "사진 변경"
            
        default :
            self.information.text = ""
        }
    }
}
