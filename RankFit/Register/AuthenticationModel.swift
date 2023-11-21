//
//  AuthenticationModel.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/14.
//

import Foundation
import Alamofire
import Combine
import FirebaseAuth
import FirebaseFirestore

final class AuthenticationModel {
    
    var userInfoData = CurrentValueSubject<userInfo?, Never>(nil)
    
    func saveKeyChain(subject: PassthroughSubject<Bool, Never>) {
        if let info = userInfoData.value {
            let UID = info.uid ?? ""
            let nickName = info.nickName ?? "정보없음"

            let calc = calcDate()
            saveUserData.setKeychain(info.email ?? "정보없음", forKey: .Email)
            saveUserData.setKeychain(UID, forKey: .UID)
            saveUserData.setKeychain(info.gender ?? 0, forKey: .Gender)
            saveUserData.setKeychain(info.birth ?? "1900-01-01", forKey: .Birth)
            
            saveUserData.setKeychain(nickName, forKey: .NickName)
            UserDefaults.standard.set(calc.after30days(), forKey: "nick_date")
            
            saveUserData.setKeychain(info.weight ?? 1, forKey: .Weight)
            UserDefaults.standard.set(calc.after1Day(), forKey: "weight_date")
            subject.send(true)
        } else {
            configFirebase.errorReport(type: "AuthenticationModel.saveKeyChain", descriptions: "error: info == nil")
            subject.send(false)
        }
    }
    
    func sendFirebaseDB(subject: PassthroughSubject<Bool, Never>) {
        if let info = userInfoData.value {
            let nickName = info.nickName ?? "정보없음"
            let UID = info.uid ?? ""
            let gender = info.gender ?? 0
            let birth = info.birth ?? "1900-01-01"
            let weight = info.weight ?? 1
            let token = saveUserData.getKeychainStringValue(forKey: .Token) ?? "Token == nil"
            let userData: [String: Any] = ["nickName": nickName, "Gender": gender, "Birth": birth, "Weight": weight, "Token": token]
            
            let db = Firestore.firestore()
            db.collection("baseInfo").document(UID).setData(userData) { error in
                if let error = error {
                    print("Firebase baseInfo에 회원 정보 저장 실패: \(error.localizedDescription)")
                    let user = Auth.auth().currentUser
                    user?.delete { error in
                        if let error = error {
                            print("Firebase에서 회원 계정 삭제 실패: \(error.localizedDescription)")
                            configFirebase.errorReport(type: "AuthenticationModel.sendFirebaseDB", descriptions: "Firebase 회원 계정 삭제 실패: " + error.localizedDescription)
                            subject.send(false)
                        } else {
                            print("Firebase에서 회원 계정 삭제 완료")
                            configFirebase.errorReport(type: "AuthenticationModel.sendFirebaseDB", descriptions: "Firebase 회원 계정 삭제 성공")
                            subject.send(false)
                        }
                    }
                } else {
                    print("Firebase baseInfo에 회원 정보 저장 성공")
                    subject.send(true)
                }
            }
        } else {
            let user = Auth.auth().currentUser
            user?.delete { error in
                if let error = error {
                    print("Firebase에서 회원 계정 삭제 실패: \(error.localizedDescription)")
                    configFirebase.errorReport(type: "AuthenticationModel.sendFirebaseDB", descriptions: "info == nil, Firebase 회원 계정 삭제 실패: " + error.localizedDescription)
                    subject.send(false)
                } else {
                    print("Firebase에서 회원 계정 삭제 완료")
                    configFirebase.errorReport(type: "AuthenticationModel.sendFirebaseDB", descriptions: "info == nil, Firebase 회원 계정 삭제 성공")
                    subject.send(false)
                }
            }
        }
    }
    
    func sendServer(subject: PassthroughSubject<Bool, Never>) {
        if let userData = userInfoData.value {
            let id = userData.uid ?? ""
            let email = userData.email ?? "정보없음" // 이메일
            let nickName = userData.nickName ?? "닉네임없음"
            let birthday = userData.birth!
            let age = calcDate().getAge(BDay: birthday)
            
            let parameters: Parameters = [
                "userID": id,           // UID
                "userEmail": email,
                "userNickname": nickName,
                "userAge": age,
                "userSex": userData.gender ?? 0,
                "userWeight": userData.weight ?? 1
            ]
            AF.request("http://mate.gabia.io/Register.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
                response in
                if let responseBody = response.value {
                    if responseBody == "true" {
                        print("서버에 회원 정보 전송 성공")
                        subject.send(true)
                    } else {
                        print("서버 전송 오류: \(responseBody)")
                        configFirebase.errorReport(type: "RegisterNickNameVC.sendServer", descriptions: "서버에 회원 정보 전송 오류", server: responseBody.debugDescription)
                        // Firebase에 등록된 유저 삭제
                        let user = Auth.auth().currentUser
                        user?.delete { error in
                            if let error = error {
                                print("Firebase에서 회원 계정 삭제 실패: \(error.localizedDescription)")
                                configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: "서버에 회원 정보 전송 오류, Firebase 회원 계정 삭제 실패: " + error.localizedDescription)
                                subject.send(false)
                            } else {
                                print("Firebase에서 회원 계정 삭제 완료")
                                configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: "서버에 회원 정보 전송 오류, Firebase 회원 계정 삭제 성공")
                                // firebase DB 정보 삭제
                                let db = Firestore.firestore()
                                db.collection("baseInfo").document(id).delete() { error in
                                    if let error = error {
                                        print("error remove document: \(error.localizedDescription)")
                                        configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: error.localizedDescription)
                                        subject.send(false)
                                    } else {
                                        print("Firebase baseInfo에서 사용자 정보 삭제 완료")
                                        subject.send(false)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Firebase auth에 등록된 유저 삭제
                    let user = Auth.auth().currentUser
                    user?.delete { error in
                        if let error = error {
                            print("Firebase에서 회원 계정 삭제 실패: \(error.localizedDescription)")
                            configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: "responseBody == nil, Firebase 회원 계정 삭제 실패: " + error.localizedDescription)
                            subject.send(false)
                        } else {
                            print("Firebase에서 회원 계정 삭제 완료")
                            configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: "error: responseBody == nil, Firebase 회원 계정 삭제 성공")
                            // firebase DB 정보 삭제
                            let db = Firestore.firestore()
                            db.collection("baseInfo").document(id).delete() { error in
                                if let error = error {
                                    print("error remove document: \(error.localizedDescription)")
                                    configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: error.localizedDescription)
                                    subject.send(false)
                                } else {
                                    print("Firebase baseInfo에서 사용자 정보 삭제 완료")
                                    subject.send(false)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            configFirebase.errorReport(type: "AuthenticationModel.sendServer", descriptions: "error: userData == nil")
            subject.send(false)
        }
    }
}
