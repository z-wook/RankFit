//
//  AuthenticationModel.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/14.
//

import Foundation
import Combine

final class AuthenticationModel {
    
    var userInfoData: CurrentValueSubject<userInfo?, Never>
    
    init(data: userInfo? = nil) {
        self.userInfoData = CurrentValueSubject(data)
    }
}
