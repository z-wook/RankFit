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
            "date": date            // 날짜
        ]
        AF.request("http://mate.gabia.io/notify.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
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
    
    static func sendSaveEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>) {
        let urlString = "http://mate.gabia.io/RegisterAerobic.php"
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
        
        requestServer(url: urlString, params: parameters, responseResult: "Data Insert Success.", subject: subject)
    }
    
    static func sendCompleteEx(info: aerobicExerciseInfo, totalDis: Double, time: Int, saveTime: Int64, subject: PassthroughSubject<Bool, Never>) {
        let urlString = "http://mate.gabia.io/UpdateAerobic.php"
        let uuid = info.id
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let tableName = info.tableName
        let dis = Double(String(format: "%.2f", totalDis)) ?? 0
        var score = round(totalDis + (totalDis / (Double(time)/60)))    // double
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        if score < 1 { score = 1 } // 점수가 0점으로 기록되는 것을 방지하기 위해 최소 점수를 1점으로 함
        
        let parameters: Parameters = [
            "uuid": uuid,
            "userID": userID,           // Firebase에서 받은 UID
            "eng": tableName,           // 테이블 이름
            "ko": info.exercise,        // 운동 명
            "userDate": saveTime,       // 운동 완료 시간(시간 갱신)
            "userDistance": dis,        // 실제 운동 거리
            "userTime": time,           // 실제 운동 시간(분)
            "Score": score,             // 거리 + 평균속도
            "userState": 1,             // 완료 1, 미완료 0
            "userSex": userGender
        ]
        print("params: \(parameters)")
        
        requestServer(url: urlString, params: parameters, responseResult: "true", subject: subject)
    }
    
    static func sendDeleteEx(info: aerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>? = nil) {
        let urlString = "http://mate.gabia.io/DeleteAerobic.php"
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let exercise = info.exercise            // String
        let tableName = info.tableName          // String
        let date_time = info.saveTime           // String
        
        let parameters: Parameters = [
            "userID": userID,           // Firebase에서 받은 UID
            "userSex": userGender,      // 성별
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "eng": tableName,           // 운동 영문이름
            "ko": info.exercise         // 운동 명
        ]
        print("parmas: \(parameters)")
        
        requestServer(url: urlString, params: parameters, responseResult: "true", subject: subject)
    }
    
    static func firebaseSave(exName: String, time: Int64, uuid: String, date: String) {
        configFirebase.saveEx(exName: exName, time: time, uuid: uuid, date: date)
    }
    
    static func sendSaveEx(info: anaerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>) {
        let urlString = "http://mate.gabia.io/RegisterAnaerobic.php"
        let uuid = info.id                      // uuid
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let exercise = info.exercise            // string
        let saveTime = info.saveTime            // int64(TimeStamp)
        let set = info.set                      // int16
        let weight = info.weight                // float
        let count = info.count                  // int16
        let exTime = info.exTime                // double(초)
        let category = info.category ?? "nil"
        
        let parameters: Parameters = [
            "uuid": uuid,               // uuid
            "userID": userID,           // Firebase에서 받은 UID
            "userExercise": exercise,   // 운동명
            "userDate": saveTime,       // 운동 저장 시간(saveTime)
            "userSet": set,             // 세트
            "userWeight": weight,       // 무게
            "userCount": count,         // exercise count(개수)
            "exTime": exTime,           // 운동 목표 시간(플랭크), 나머지 운동은 default값 = 0으로 입력
            "userState": 0,             // 완료 1, 미완료 0
            "category": category        // 부위(String)
        ]
        print("params: \(parameters)")
        
        requestServer(url: urlString, params: parameters, responseResult: "Data Insert Success.", subject: subject)
    }
    
    static func sendCompleteEx(info: anaerobicExerciseInfo, time: Int, saveTime: Int64, subject: PassthroughSubject<Bool, Never>) {
        let urlString = "http://mate.gabia.io/UpdateAnaerobic.php"
        let uuid = info.id
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let tableName = info.tableName  // String
        var score: Float!
        if info.exercise == "플랭크" {
            let floatScore = Float(info.set) * Float(info.exTime)
            score = floatScore
        } else {
            let floatScore = Float(info.set * info.count)
            score = floatScore
        }
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        
        let parameters: Parameters = [
            "uuid": uuid,               // UUID
            "userID": userID,           // Firebase에서 받은 UID
            "eng": tableName,           // 테이블 이름
            "ko": info.exercise,        // 운동 명
            "userDate": saveTime,       // 운동 완료 시간(시간 갱신)
            "Score": score ?? 0,        // 점수
            "userTime": time,           // 운동 시간(초)
            "userState": 1,             // 완료 1, 미완료 0
            "userSex": userGender
        ]
        print("params: \(parameters)")

        requestServer(url: urlString, params: parameters, responseResult: "true", subject: subject)
    }
    
    static func sendDeleteEx(info: anaerobicExerciseInfo, subject: PassthroughSubject<Bool, Never>?) {
        let urlString = "http://mate.gabia.io/DeleteAnaerobic.php"
        let userID = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let userGender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let exercise = info.exercise    // string
        let date_time = info.saveTime   // string
        let tableName = info.tableName
        
        let parameters: Parameters = [
            "userID": userID,           // Firebase에서 받은 UID
            "userSex": userGender,      // 성별
            "userExercise": exercise,   // 운동 이름
            "userDate": date_time,      // 운동 저장 날짜(saveTime)
            "eng": tableName,
            "ko": info.exercise
        ]
        print("params: \(parameters)")
        
        requestServer(url: urlString, params: parameters, responseResult: "true", subject: subject)
    }
}

extension configServer {
    private static func requestServer(url: String, params: Parameters, responseResult: String, subject: PassthroughSubject<Bool, Never>? = nil) {
        Task {
            do {
                let value = try await sendToServer(url: url, params: params)
                if value == responseResult {
                    return subject?.send(true)
                }
                configFirebase.errorReport(type: "configServer", descriptions: "value: \(value)", server: value.debugDescription)
                subject?.send(false)
            } catch {
                print("Error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configServer", descriptions: "requestServer Error", server: error.localizedDescription)
                subject?.send(false)
            }
        }
    }
    
    private static func sendToServer(url: String, params: Parameters) async throws -> String {
        var retryCount = 0
        while retryCount < 3 {
            do {
                return try await AF.request(url, method: .post, parameters: params).serializingString().value // decodeJson으로 해보기
            } catch {
                print("Send Server Error: \(error.localizedDescription)")
                retryCount += 1
                if retryCount > 3 {
                    throw error
                }
            }
        }
        // This should never be reached
        throw NSError(domain: "MaxRetryCountExceeded", code: 0)
    }
}
