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
    
    static func firebaseSave(exName: String, time: Int64, uuid: String, date: String, subject: PassthroughSubject<Bool, Never>) {
        configFirebase.saveEx(exName: exName, time: time, uuid: uuid, date: date, subject: subject)
    }
    
    static func sendSaveEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>) {
        let uuid = info.id
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let exercise = info.exercise            // String
        let saveTime = info.saveTime            // Int64
        let distance = info.distance            // Double
        let time = info.time                    // Int16
        
        let parameters: Parameters = [
            "uuid": uuid,               // UUID
            "userID": userID,           // Firebase에서 받은 UID
            "userExercise": exercise,   // 운동 이름
            "userDate": saveTime,       // 운동 저장 날짜
            "userDistance": distance,   // 목표 거리
            "userTime": time,           // 목표 시간
            "userState": 0              // 완료 1, 미완료 0
        ]
        print("params: \(parameters)")
        
        AF.request("http://rankfit.site/RegisterAerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "Data Insert Success." {
                    subject.send(true)
                } else {
                    configFirebase.errorReport(type: "SendAerobicEx.sendSaveEx", descriptions: "서버에 운동 저장 실패/responseBody != Data Insert Success.", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "SendAerobicEx.sendSaveEx", descriptions: "서버에 운동 저장 실패/responseBody = nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    static func sendCompleteEx(info: aerobicExerciseInfo, totalDis: Double, time: Int, saveTime: Int64, subject: PassthroughSubject<Bool, Never>) {
        let uuid = info.id
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let tableName = info.tableName                              // string
        let score = totalDis + (totalDis / (Double(time)/60))       // double
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let start_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start")
        let end_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        
        let parameters: Parameters = [
            "uuid": uuid,
            "userID": userID,           // Firebase에서 받은 UID
            "eng": tableName,           // 테이블 이름
            "userDate": saveTime,       // 운동 완료 시간(시간 갱신)
            "userDistance": totalDis,   // 실제 운동 거리
            "userTime": time,           // 실제 운동 시간(분)
            "Score": score,             // 거리 + 평균속도
            "userState": 1,             // 완료 1, 미완료 0
            "userSex": userGender,
            "start": start_Timestamp,
            "end": end_Timestamp
        ]
        print("params: \(parameters)")
        
        AF.request("http://rankfit.site/UpdateAerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "true" { // success
                    subject.send(true)
                } else {
                    configFirebase.errorReport(type: "SendAerobicEx.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/responseBody != true", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "SendAerobicEx.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/responseBody = nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    static func sendDeleteEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>?) {
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let exercise = info.exercise            // String
        let tableName = info.tableName          // String
        let date_time = info.saveTime           // String
        let start_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start")
        let end_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        
        let parameters: Parameters = [
            "userID": userID,           // Firebase에서 받은 UID
            "userSex": userGender,      // 성별
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "eng": tableName,           // 운동 영문이름
            "start": start_Timestamp,
            "end": end_Timestamp
        ]
        print("parmas: \(parameters)")
        
        AF.request("http://rankfit.site/DeleteAerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "true" { // success
                    print("서버에서 운동 삭제 성공")
                    subject?.send(true)
                } else {
                    configFirebase.errorReport(type: "SendAerobicEx.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/responseBody != true", server: responseBody.debugDescription)
                    subject?.send(false)
                }
            } else {
                configFirebase.errorReport(type: "SendAerobicEx.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/responseBody = nil", server: response.debugDescription)
                subject?.send(false)
            }
        }
    }
}
