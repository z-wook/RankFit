//
//  configServer.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/18.
//

import Foundation
import Alamofire
//import FirebaseFirestore
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
            "date": date            // 날짜
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
    
    static func sendSaveEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>){
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
                    configFirebase.errorReport(type: "configServer.sendSaveEx", descriptions: "서버에 운동 저장 실패/responseBody != Data Insert Success.", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "configServer.sendSaveEx", descriptions: "서버에 운동 저장 실패/responseBody = nil", server: response.debugDescription)
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
                    configFirebase.errorReport(type: "configServer.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/responseBody != true", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "configServer.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/responseBody = nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    static func sendDeleteEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>? = nil) {
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
                    configFirebase.errorReport(type: "configServer.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/responseBody != true", server: responseBody.debugDescription)
                    subject?.send(false)
                }
            } else {
                configFirebase.errorReport(type: "configServer.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/responseBody = nil", server: response.debugDescription)
                subject?.send(false)
            }
        }
    }
    
    static func firebaseSave(exName: String, time: Int64, uuid: String, date: String) {
        configFirebase.saveEx(exName: exName, time: time, uuid: uuid, date: date)
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
                    configFirebase.errorReport(type: "configServer.sendSaveEx", descriptions: "서버에 운동 저장 실패/responseBody != Data Insert Success.", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "configServer.sendSaveEx", descriptions: "response.value = nil", server: response.debugDescription)
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
                    configFirebase.errorReport(type: "configServer.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/responseBody != true", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "configServer.sendCompleteEx", descriptions: "서버에 완료 운동 업데이트 실패/response.value = nil", server: response.debugDescription)
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
                    configFirebase.errorReport(type: "configServer.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/responseBody != true", server: responseBody.debugDescription)
                    subject?.send(false)
                }
            } else {
                configFirebase.errorReport(type: "configServer.sendDeleteEx", descriptions: "서버에서 운동 삭제 실패/response.value = nil", server: response.debugDescription)
                subject?.send(false)
            }
        }
    }
}
