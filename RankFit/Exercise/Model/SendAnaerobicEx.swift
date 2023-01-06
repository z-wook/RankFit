//
//  SendAnaerobicEx.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/26.
//

import Foundation
import Alamofire
import Combine

final class SendAnaerobicEx {
    
    static func sendSaveEx(info: anaerobicExerciseInfo) {
        let userID = getUserInfo().getUserID()  // string
        let exercise = info.exercise            // string
        let date_time = info.saveTime           // string
        let set = info.set                      // int16
        let weight = info.weight                // float
        let count = info.count                  // int16
        
        let parameters: Parameters = [
            "userID": userID,
            "userExercise": exercise,
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "userSet": set,             // 세트
            "userWeight": weight,       // 무게
            "userCount": count,         // exercise count(개수)
            "userState": 0              // 완료 1, 미완료 0
        ]
        
        AF.request("http://rankfit.site/RegisterAnaerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("====== response: \(response)")
            if let responseBody = response.value {
                if responseBody == "Data Insert Success." { // success
                    saveExerciseViewController1.sendState.send(true)
                } else { // fail
                    saveExerciseViewController1.sendState.send(false)
                }
            } else {
                saveExerciseViewController1.sendState.send(false)
            }
        }
    }
    
    static func sendCompleteEx(info: anaerobicExerciseInfo, time: Int) {
        let userInfo = getUserInfo()
        let userID = userInfo.getUserID()               // string
        let exercise = info.exercise                    // string
        let date_time = info.saveTime                   // string
        let set = info.set                              // int16
        let weight = info.weight                        // float
        let count = info.count                          // int16
        let score = Float(time) / Float(set * count)    // float
        let changed_score = Float(String(format: "%.2f", score)) ?? 0
        let userGender = userInfo.getGender()           // int
        
        let parameters: Parameters = [
            "userID": userID,           // 사용자 ID
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "userSet": set,             // 세트
            "userWeight": weight,       // 무게
            "userCount": count,         // exercise count(개수)
            "Score": changed_score,     // 점수
            "userTime": time,           // 운동 시간
            "userState": 1,             // 완료 1, 미완료 0
            "userSex": userGender
        ]
        
        AF.request("http://rankfit.site/UpdateAnaerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("====== response: \(response)")
            if let responseBody = response.value {
                if responseBody == "true" { // success // Data Insert Success.
                    AnaerobicActivityViewController.sendState.send(true)
                } else { // fail
                    AnaerobicActivityViewController.sendState.send(false)
                }
            } else {
                AnaerobicActivityViewController.sendState.send(false)
            }
        }
    }
    
    static func sendDeleteEx(info: anaerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>) {
        let userID = getUserInfo().getUserID()  // string
        let exercise = info.exercise            // string
        let date_time = info.saveTime           // string
        
        let parameters: Parameters = [
            "userID": userID,           // 사용자 ID
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
        ]
        
        AF.request("http://rankfit.site/DeleteAnaerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("====== response: \(response)")
            if let responseBody = response.value {
                if responseBody == "true" { // success // Data Insert Success.
                    subject.send(true)
                } else { // fail
                    subject.send(false)
                }
            } else {
                subject.send(false)
            }
        }
    }
}
