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
        
    }
    
    func configCell(title: String, infomation: String) {
        self.title.text = title
        
        switch title {
        case "이메일": self.infomation.text = infomation
            
        case "성별":
            if infomation == "0" {
                self.infomation.text = "남성"
            } else if infomation == "1" {
                self.infomation.text = "여성"
            } else { return }
            
        case "나이":
            self.infomation.text = "만 " + infomation + "세"
            
        case "몸무게":
            self.infomation.text = infomation + "kg"
        
        case "닉네임":
            self.infomation.text = infomation
            
        case "프로필":
            self.infomation.text = "사진 변경"
            
        default :
            self.infomation.text = ""
        }
    }
}
