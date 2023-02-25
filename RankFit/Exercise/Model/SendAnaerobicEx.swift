//
//  SendAnaerobicEx.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/26.
//

import Foundation
import Alamofire
import Combine
import FirebaseFirestore

final class SendAnaerobicEx {
    
    static func firebaseSave(exName: String, time: Int64, uuid: String, date: String, subject: PassthroughSubject<Bool, Never>) {
        configFirebase.saveEx(exName: exName, time: time, uuid: uuid, date: date, subject: subject)
    }
    
    static func sendSaveEx(info: anaerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>) {
        let uuid = info.id                      // uuid
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let exercise = info.exercise            // string
        let saveTime = info.saveTime            // int64(TimeStamp)
        let set = info.set                      // int16
        let weight = info.weight                // float
        let count = info.count                  // int16
        let exTime = info.exTime                // double(초)
        
        let parameters: Parameters = [
            "uuid": uuid,               // uuid
            "userID": userID,           // Firebase에서 받은 UID
            "userExercise": exercise,   // 운동명
            "userDate": saveTime,       // 운동 저장 시간(saveTime)
            "userSet": set,             // 세트
            "userWeight": weight,       // 무게
            "userCount": count,         // exercise count(개수)
            "exTime": exTime,           // 운동 목표 시간(플랭크), 나머지 운동은 default값 = 0으로 입력
            "userState": 0              // 완료 1, 미완료 0
        ]
        
        print("params: \(parameters)")
        
        AF.request("http://rankfit.site/RegisterAnaerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "Data Insert Success." { // success
                    subject.send(true)
                } else {
                    configFirebase.errorReport(type: "SendAnaerobicEx.sendSaveEx", descriptions: "서버에 운동 저장 실패/responseBody != Data Insert Success.", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "SendAnaerobicEx.sendSaveEx", descriptions: "response.value = nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    static func sendCompleteEx(info: anaerobicExerciseInfo, time: Int, saveTime: Int64, subject: PassthroughSubject<Bool, Never>) {
        let uuid = info.id
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let tableName = info.tableName  // String
        var score: Float!
        if info.exercise == "플랭크" {
            let floatScore = Float(info.set) * Float(info.exTime)
            let changed_score = Float(String(format: "%.2f", floatScore)) ?? 0
            score = changed_score
        } else {
            let floatScore = Float(time) / Float(info.set * info.count)  // float
            let changed_score = Float(String(format: "%.2f", floatScore)) ?? 0
            score = changed_score
        }
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let start_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start")
        let end_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        
        let parameters: Parameters = [
            "uuid": uuid,               // UUID
            "userID": userID,           // Firebase에서 받은 UID
            "eng": tableName,           // 테이블 이름
            "userDate": saveTime,       // 운동 완료 시간(시간 갱신)
            "Score": score ?? 0,        // 점수
            "userTime": time,           // 운동 시간(초)
            "userState": 1,             // 완료 1, 미완료 0
            "userSex": userGender,
            "start": start_Timestamp,
            "end": end_Timestamp
        ]
        print("params: \(parameters)")

        AF.request("http://rankfit.site/UpdateAnaerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "true" { // success // Data Insert Success.
                    subject.send(true)
                } else {
                    configFirebase.errorReport(type: "SendAnaerobicEx.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/responseBody != true", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "SendAnaerobicEx.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/response.value = nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    static func sendDeleteEx(info: anaerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>?) {
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let exercise = info.exercise    // string
        let date_time = info.saveTime   // string
        let tableName = info.tableName
        let start_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start")
        let end_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        
        let parameters: Parameters = [
            "userID": userID,           // Firebase에서 받은 UID
            "userSex": userGender,      // 성별
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "eng": tableName,
            "start": start_Timestamp,
            "end": end_Timestamp
        ]
        print("params: \(parameters)")
        
        AF.request("http://rankfit.site/DeleteAnaerobic.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "true" { // success
                    print("서버에서 운동 삭제 성공")
                    subject?.send(true)
                } else {
                    configFirebase.errorReport(type: "SendAnaerobicEx.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/responseBody != true", server: responseBody.debugDescription)
                    subject?.send(false)
                }
            } else {
                configFirebase.errorReport(type: "SendAnaerobicEx.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/response.value = nil", server: response.debugDescription)
                subject?.send(false)
            }
        }
    }
}
