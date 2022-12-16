//
//  userInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/13.
//

import Foundation

struct userInfo {
    var gender: Int?
    var age: Int?
    var weight: Int?
    var userID: String?
    var nickName: String?
    var email: String?
    
    init(gender: Int? = nil, age: Int? = nil, weight: Int? = nil, userID: String? = nil, nickName: String? = nil, email: String? = nil) {
        self.gender = gender // 남성은 0, 여성은 1
        self.age = age
        self.weight = weight
        self.userID = userID
        self.nickName = nickName
        self.email = email
    }
}
