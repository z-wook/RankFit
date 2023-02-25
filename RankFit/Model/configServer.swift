//
//  configServer.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/18.
//

import Foundation
import Alamofire
import Combine

final class configServer {
    
    // 0. 부적절한 프로필 사진
    // 1. 부적절한 닉네임
    // 2. 랭킹 오류 / 랭킹 악용 의심
    static func reportUser(nickName: String, reason: Int, subject: PassthroughSubject<String, Never>) {
        let uid = saveUserData.getKeychainStringValue(forKey: .UID) ?? "익명"
        let date = getDateString.getCurrentDate_Time()
        
        let parameters: Parameters = [
            "nickname": nickName,   // 신고 대상
            "reason": reason,       // 사유
            "userID": uid,          // 신고자
            "date":  date           // 날짜
        ]
        AF.request("http://rankfit.site/notify.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "true" {
                    subject.send("done")
                } else { // responseBody == "Already reported it!!" / 이미 신고 한 유저
                    subject.send("already")
                }
            } else {
                print("response.value == nil")
                configFirebase.errorReport(type: "configServer.reportUser", descriptions: "responseBody == nil", server: response.debugDescription)
                subject.send("fail")
            }
        }
    }
}
