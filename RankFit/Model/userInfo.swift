//
//  userInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/13.
//

import Foundation

struct userInfo {
    var gender: Int?
    var birth: String?
    var weight: Int?
    var uid: String?
    var email: String?
    var nickName: String?
    
    init(gender: Int? = nil, birth: String? = nil, weight: Int? = nil, uid: String? = nil, email: String? = nil, nickName: String? = nil) {
        self.gender = gender // 남성은 0, 여성은 1로 서버에 전송하기
        self.birth = birth
        self.weight = weight
        self.uid = uid
        self.email = email
        self.nickName = nickName
    }
}
