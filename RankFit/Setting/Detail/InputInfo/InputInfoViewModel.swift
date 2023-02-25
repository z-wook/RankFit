//
//  InputInfoViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/15.
//

import Foundation
import Alamofire
import Combine

final class InputInfoViewModel {
    
    let uid = saveUserData.getKeychainStringValue(forKey: .UID)
    
    func deleteFromServer(subject: PassthroughSubject<Bool, Never>) {
        guard let uid = uid else {
            configFirebase.errorReport(type: "InputInfoVM.deleteFromServer", descriptions: "uid == nil")
            subject.send(false)
            return
        }
        let parameters: Parameters = [
            "image_name": uid + ".jpeg"
        ]
        AF.request("http://rankfit.site/imageDelete.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "Success" {
                    print("서버에서 프로필 사진 삭제 성공")
                    subject.send(true)
                } else { // responseBody == "Fail"
                    print("서버에서 프로필 사진 삭제 실패")
                    configFirebase.errorReport(type: "InputInfoVM.deleteFromServer", descriptions: "responseBody == Fail", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                print("response.value == nil")
                configFirebase.errorReport(type: "InputInfoVM.deleteFromServer", descriptions: "response.value == nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    func uploadToServer(ImageData: Data, subject: PassthroughSubject<Bool, Never>) {
        guard let uid = uid else {
            configFirebase.errorReport(type: "InputInfoVM.uploadToServer", descriptions: "uid == nil")
            subject.send(false)
            return
        }
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(ImageData, withName: "image", fileName: uid + ".jpeg", mimeType: "image/jpeg")
        }, to: "http://rankfit.site/image.php").response { response in
            if let error = response.error {
                print("Error uploading image: \(error.localizedDescription)")
                configFirebase.errorReport(type: "InputInfoVM.uploadToServer", descriptions: error.localizedDescription, server: response.debugDescription)
                subject.send(false)
                return
            }
            print("서버에 프로필 사진 업데이트 성공")
            subject.send(true)
        }
    }
    
    func sendNickName(nickName: String, subject: PassthroughSubject<Bool, Never>) {
        let id = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let email = saveUserData.getKeychainStringValue(forKey: .Email) ?? "정보없음"
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth ?? "1900")
        let gender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let weight = saveUserData.getKeychainIntValue(forKey: .Weight) ?? 1
        
        let parameters: Parameters = [
            "userID": id,
            "userEmail": email,
            "userNickname": nickName,
            "userAge": age,
            "userSex": gender ,
            "userWeight": weight
        ]
        AF.request("http://rankfit.site/Register.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString { response in
            if let responseBody = response.value {
                if responseBody == "true" {
                    subject.send(true)
                } else { // false
                    configFirebase.errorReport(type: "InputInfoVM.sendNickName", descriptions: "responseBody == false", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "InputInfoVM.sendNickName", descriptions: "responseBody == nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    func nickNameCheck(nickName: String, subject: PassthroughSubject<Bool, Never>) {
        let parameters: Parameters = [
            "userNickname": nickName
        ]
        AF.request("http://rankfit.site/Check.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            if let responseBody = response.value {
                if responseBody == "true" {
                    subject.send(true)
                } else {
                    configFirebase.errorReport(type: "InputInfoVM.nickNameCheck", descriptions: "responseBody == false", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                configFirebase.errorReport(type: "InputInfoVM.nickNameCheck", descriptions: "responseBody == nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
    
    func sendWeightToServer(newWeight: Int, subject: PassthroughSubject<Bool, Never>) {
        let id = saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        let email = saveUserData.getKeychainStringValue(forKey: .Email) ?? "정보없음"
        let nickName = saveUserData.getKeychainStringValue(forKey: .NickName) ?? "정보없음"
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth ?? "1990")
        let gender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        
        let parameters: Parameters = [
            "userID": id,   // 플랫폼 고유 아이디
            "userEmail": email,
            "userNickname": nickName,
            "userAge": age,
            "userSex": gender,
            "userWeight": newWeight
        ]
        AF.request("http://rankfit.site/Register.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("response: \(response)")
            if let responseBody = response.value {
                if responseBody == "true" {
                    // 키체인은 덮어쓰기가 안되기 때문에 기존에 저장된 값 삭제 후 새로운 값 저장
                    saveUserData.removeKeychain(forKey: .Weight)
                    saveUserData.setKeychain(newWeight, forKey: .Weight)
                    UserDefaults.standard.set(calcDate().after1Day(), forKey: "weight_date")
                    MyProfileViewController.userWeight.send(newWeight)
                    subject.send(true)
                } else { // responseBody == "false"
                    print("error: responseBody == false")
                    configFirebase.errorReport(type: "InputInfoVM.sendWeightToServer", descriptions: "responseBody == false", server: responseBody.debugDescription)
                    subject.send(false)
                }
            } else {
                print("error: responseBody == nil")
                configFirebase.errorReport(type: "InputInfoVM.sendWeightToServer", descriptions: "responseBody == nil", server: response.debugDescription)
                subject.send(false)
            }
        }
    }
}
