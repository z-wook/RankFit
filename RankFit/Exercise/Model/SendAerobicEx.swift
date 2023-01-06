//
//  SendAerobicEx.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/26.
//

import Foundation
import Alamofire
import Combine

final class SendAerobicEx {
    
    static func sendSaveEx(info: aerobicExerciseInfo) {
        let userID = getUserInfo().getUserID()  // string
        let exercise = info.exercise            // string
        let date_time = info.saveTime           // string
        let distance = info.distance            // double
        let time = info.time                    // int16
        
        let parameters: Parameters = [
            "userID": userID,           // 고유 ID
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜
            "userDistance": distance,   // 목표 거리
            "userTime": time,           // 목표 시간
            "userState": 0              // 완료 1, 미완료 0
        ]
        
        AF.request("http://rankfit.site/RegisterAerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("====== response: \(response)")
            if let responseBody = response.value {
                if responseBody == "Data Insert Success." { // success
                    saveExerciseViewController2.sendState.send(true)
                } else { // fail
                    saveExerciseViewController2.sendState.send(false)
                }
            } else {
                saveExerciseViewController2.sendState.send(false)
            }
        }
    }
        
    static func sendCompleteEx(info: aerobicExerciseInfo, totalDis: Double, time: Int) {
        let userInfo = getUserInfo()
        let userID = userInfo.getUserID()                           // string
        let exercise = info.exercise                                // string
        let date_time = info.saveTime                               // string
        let score = totalDis + (totalDis / Double((time / 60)))     // double
        let userGender = userInfo.getGender()
        
        let parameters: Parameters = [
            "userID": userID,
            "userExercise": exercise,
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "userDistance": totalDis,       // 실제 운동 거리
            "userTime": time,               // 실제 운동 시간(분)
            "Score": score,             // 거리 + 평균속도
            "userState": 1,             // 완료 1, 미완료 0
            "userSex": userGender
        ]
        
        AF.request("http://rankfit.site/UpdateAerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("====== response: \(response)")
            if let responseBody = response.value {
                if responseBody == "true" { // success
                    AerobicActivityViewController.sendState.send(true)
                } else { // fail
                    AerobicActivityViewController.sendState.send(false)
                }
            } else {
                AerobicActivityViewController.sendState.send(false)
            }
        }
    }
    
    static func sendDeleteEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>) {
        let userID = getUserInfo().getUserID()  // string
        let exercise = info.exercise            // string
        let date_time = info.saveTime           // string
        
        let parameters: Parameters = [
            "userID": userID,           // 사용자 ID
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
        ]
        
        AF.request("http://rankfit.site/DeleteAerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
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
