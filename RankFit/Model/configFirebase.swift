//
//  configFirebase.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/18.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

final class configFirebase {
    
    private static let storage = Storage.storage()
    private static let storageRef = storage.reference()
    private static let UID = saveUserData.getKeychainStringValue(forKey: .UID)!

    // 에러 보고
    static func errorReport(type: String, descriptions: String, server: String? = nil) {
        let db = Firestore.firestore()
        db.collection("Report").document(getDateString.getCurrentDate_Time()).setData([
            type: descriptions,
            "Server": server ?? "nil"
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
            } else {
                print("에러 보고 완료 !!!")
            }
        }
    }
    
    // 문의하기
    static func ask(Ask: String, subject: PassthroughSubject<Bool, Never>) {
        let db = Firestore.firestore()
        db.collection("Ask").document(getDateString.getCurrentDate_Time()).setData([
            "Date": getDateString.getCurrentDate_Time(),
            "ID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "익명",
            "Ask": Ask
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                subject.send(false)
            } else {
                print("문의 완료")
                subject.send(true)
            }
        }
    }
    
    // 이동수단 감지 보고
    static func reportAutomotive(type: String, speed: String) {
        let db = Firestore.firestore()
        db.collection("AutomobileReport").document(getDateString.getCurrentDate_Time()).setData([
            "Type": type,
            "Speed": speed
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
            } else {
                print("이동수단 감지 보고 완료 !!!")
            }
        }
    }
    
    static func userReport(nickName: String, reason: Int) {
        // 0. 부적절한 프로필 사진
        // 1. 부적절한 닉네임
        // 2. 랭킹 오류 / 랭킹 악용 의심
        let uid = saveUserData.getKeychainStringValue(forKey: .UID) ?? "익명"
        let date = getDateString.getCurrentDate_Time()
        let db = Firestore.firestore()
        db.collection("UserReport").document(getDateString.getCurrentDate_Time()).setData([
            "Target": nickName, // 신고 대상
            "Reason": reason,   // 사유
            "userID": uid,      // 신고자
            "Date": date        // 날짜
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                errorReport(type: "configFirebase.userReport", descriptions: "Target: \(nickName), Reason: \(reason), userID: \(uid)")
            } else {
                print("사용자 신고 완료 !")
            }
        }
    }
    
    // 서버에서 사진 파일 삭제(탈퇴시 사용)
    static func removeFireStorage(subject: PassthroughSubject<Bool, Never>) {
        let typeRef = storageRef.child("privStore")
        let imagesRef = typeRef.child(UID)
        imagesRef.listAll { list, error in
            if let error = error {
                print("remove photo error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.removeFireStorage", descriptions: error.localizedDescription)
                subject.send(false)
                return
            }
            guard let list = list else {
                print("configFirebase.removeFireStorage / list == nil")
                configFirebase.errorReport(type: "configFirebase.removeFireStorage", descriptions: "list == nil")
                subject.send(false)
                return
            }
            for i in list.items {
                imagesRef.child(i.name).delete { error in
                    if let error = error {
                        configFirebase.errorReport(type: "configFirebase.removeFireStorage", descriptions: error.localizedDescription)
                        subject.send(false)
                        return
                    }
                    if i == list.items.last {
                        print("Delete FireStorage Success")
                        configFirebase.removeFirestore_userData(subject: subject)
                        return
                    }
                }
            }
        }
        configFirebase.removeFirestore_userData(subject: subject)
    }
    
    // 서버에서 자신의 운동 데이터 삭제(탈퇴시 사용)
    private static func removeFirestore_userData(subject: PassthroughSubject<Bool, Never>) {
        let db = Firestore.firestore()
        let ref = db.collection("userData").document("saveExInfo").collection(configFirebase.UID)
        ref.getDocuments { snapshot, error in
            guard let snapshot = snapshot else {
                configFirebase.errorReport(type: "configFirebase.removeFirestore", descriptions: "snapshot == nil")
                subject.send(false)
                return
            }
            for i in snapshot.documents {
                ref.document(i.documentID).delete { error in
                    if let error = error {
                        print("서버에서 운동 삭제 실패")
                        configFirebase.errorReport(type: "configFirebase,removeFirestore", descriptions: error.localizedDescription)
                        subject.send(false)
                        return
                    } else {
                        if i == snapshot.documents.last {
                            print("Success Delete userData")
                            removeFirestore_baseInfo(subject: subject)
                            return
                        }
                    }
                }
            }
        }
        removeFirestore_baseInfo(subject: subject)
    }
    
    // 서버에서 자신의 파일 삭제(탈퇴시 사용)
    private static func removeFirestore_baseInfo(subject: PassthroughSubject<Bool, Never>) {
        let db = Firestore.firestore()
        db.collection("baseInfo").document(configFirebase.UID).delete() { error in
            if let error = error {
                print("error remove document: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.removeFirestore", descriptions: error.localizedDescription)
                subject.send(false)
            } else {
                print("Success Delete baseInfo")
                deleteAuth(subject: subject)
                return
            }
        }
    }
    
    // 서버에서 회원 탈퇴(탈퇴시 사용)
    private static func deleteAuth(subject: PassthroughSubject<Bool, Never>) {
        let user = Auth.auth().currentUser
        user?.delete { error in
            if let error = error {
                configFirebase.errorReport(type: "configFirebase.deleteAuth", descriptions: error.localizedDescription)
                subject.send(false)
            } else {
                print("Firebase 회원탈퇴 성공")
                subject.send(true)
            }
        }
    }
    
    // 서버에서 해당 사진 삭제
    static func deleteImageFromFirebase(type: String? = nil, imageName: String, subject: PassthroughSubject<Bool, Never>) {
        let typeRef = storageRef.child("privStore")
        let imagesRef = typeRef.child(UID)
        var imgName: String!
        if type == "profile" {
            imgName = "profileImage"
        } else {
            let startIndex = imageName.index(imageName.startIndex, offsetBy: 0) // 시작 인덱스
            let endIndex = imageName.index(imageName.startIndex, offsetBy: 47) // 끝 인덱스
            let sliced_str = String(imageName[startIndex ..< endIndex])
            imgName = sliced_str
        }
        let spaceRef = imagesRef.child(imgName)
        spaceRef.delete { error in
            if let error = error {
                print("Firebase에서 이미지 삭제 실패")
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.deleteImageFromFirebase", descriptions: error.localizedDescription)
                subject.send(false)
            } else {
                print("Firebase에서 이미지 삭제 성공")
                subject.send(true)
            }
        }
    }
    
    // baseInfo Token 업데이트
    static func updateToken(Token: String) {
        let uid = saveUserData.getKeychainStringValue(forKey: .UID)!
        let db = Firestore.firestore()
        db.collection("baseInfo").document(uid).updateData([
            "Token": Token
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.updateToken", descriptions: "\(uid), Token: \(Token)_" + error.localizedDescription) // 실패 시 수동으로 입력하기 위해 에러로 전송
            } else {
                print("baseInfo Token값 변경 완료")
            }
        }
    }
    
    // baseInfo 닉네임 업데이트
    static func updateNickName(nickName: String, subject: PassthroughSubject<Bool, Never>) {
        let uid = saveUserData.getKeychainStringValue(forKey: .UID)!
        let db = Firestore.firestore()
        db.collection("baseInfo").document(uid).updateData([
            "nickName": nickName
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.updateNickName", descriptions: error.localizedDescription)
                subject.send(false)
            } else {
                print("baseInfo 닉네임 변경 완료")
                subject.send(true)
            }
        }
    }
    
    // baseInfo 몸무게 업데이트
    static func updateWeight(weight: Int, subject: PassthroughSubject<Bool, Never>) {
        let uid = saveUserData.getKeychainStringValue(forKey: .UID)!
        let db = Firestore.firestore()
        db.collection("baseInfo").document(uid).updateData([
            "Weight": weight
        ]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.updateWeight", descriptions: error.localizedDescription)
                subject.send(false)
            } else {
                print("baseInfo 몸무게 변경 완료")
                subject.send(true)
            }
        }
    }
    
    // 서버에서 사진 다운
    static func downloadImage(imgNameList: [String], subject: PassthroughSubject<String, Never>) {
        let typeRef = storageRef.child("privStore")
        let imagesRef = typeRef.child(UID)
        
        for imgName in imgNameList {
            print("imageName: \(imgName)")
            let storageReference = imagesRef.child(imgName)
            let megaByte = Int64(10 * 1024 * 1024)
            storageReference.getData(maxSize: megaByte) { data, error in
                if let error = error {
                    print("error: \(error.localizedDescription)")
                    configFirebase.errorReport(type: "configFirebase.downloadImage", descriptions: error.localizedDescription)
                    return
                } else {
                    guard let imageData = data else {
                        print("error: data == nil")
                        configFirebase.errorReport(type: "configFirebase.downloadImage", descriptions: "error: data == nil")
                        return
                    }
                    // 로컬에 사진 저장
                    configLocalStorage.saveImageToLocal(imageName: imgName, imgData: imageData, subject: subject)
                }
            }
        }
    }
    
    // 서버에서 사진 이름 가져오기
    static func getImgNameFromFirebase(subject: PassthroughSubject<[String], Never>) {
        let typeRef = storageRef.child("privStore")
        let imagesRef = typeRef.child(UID)
        imagesRef.listAll { snapshot, error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.getImgNameToFirebase", descriptions: error.localizedDescription)
                return
            }
            guard let snapshot = snapshot else {
                print("error: snapshot error")
                configFirebase.errorReport(type: "configFirebase.getImgNameToFirebase", descriptions: "snapshot = nil")
                return
            }
            let imageNameList = snapshot.items.map { item in
                return item.name
            }
            subject.send(imageNameList)
        }
    }
    
    // 서버에 사진 저장
    static func savePhoto(type: String? = nil, imgData: Data, subject: PassthroughSubject<String, Never>) {
        let typeRef = storageRef.child("privStore")
        let imagesRef = typeRef.child(UID)
        let imageName: String!
        if type == "profile" {
            imageName = "profileImage"
        } else { // 이미지 이름, 로컬에 저장되는 이름과 동일하게 저장
            imageName = generateFileName()
        }
        let spaceRef = imagesRef.child(imageName)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        spaceRef.putData(imgData, metadata: metaData) { metadata, error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.savePhoto", descriptions: error.localizedDescription)
                subject.send("false")
                return
            }
            guard let metadata = metadata else {
                print("error: metadata = nil")
                configFirebase.errorReport(type: "configFirebase.savePhoto", descriptions: "metadata = nil")
                subject.send("false")
                return
            }
            guard let metaPath = metadata.path else {
                print("error: metaPath = nil")
                configFirebase.errorReport(type: "configFirebase.savePhoto", descriptions: "metaPath = nil")
                subject.send("false")
                return
            }
            let URL = "gs://" + metadata.bucket + metaPath
            print("Firebase 사진 저장 성공")
            print("URL: \(URL)")
            subject.send(imageName)
        }
    }
    
    private static func generateFileName() -> String {
        let timeStamp = Int(Date().timeIntervalSince1970)
        let filename = "\(timeStamp)" + "_" + UUID().uuidString
        return filename
    }
    
    // 서버에서 운동 삭제(덮어쓰기)
    static func deleteEx(date: String, uuid: String, subject: PassthroughSubject<Bool, Never>) {
        var exList: [[String: Any]] = []
        let db = Firestore.firestore()
        db.collection("userData").document("saveExInfo").collection(UID).document(date).getDocument { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.deleteEx", descriptions: error.localizedDescription)
                subject.send(false)
                return
            } else {
                guard let snapshot = snapshot else { return }
                if snapshot.exists { // 파일이 존재 할 때, 저장된 값과 합해서 다시 저장
                    guard let data = snapshot.data() as? [String: [Any]] else {
                        print("error: dataType error")
                        configFirebase.errorReport(type: "configFirebase.deleteEx", descriptions: "snapshot.data Type error")
                        subject.send(false)
                        return
                    }
                    if let infoList = data["info"] {
                        guard let info = infoList as? [[String: Any]] else {
                            print("error: dataType error")
                            configFirebase.errorReport(type: "configFirebase.deleteEx", descriptions: "infoList Type error")
                            subject.send(false)
                            return
                        }
                        for i in 0...info.count-1 {
                            let aaa = info[i]["uuid"] as! String
                            if uuid == aaa { continue }
                            exList.append(info[i])
                        }
                        print("saveExList: \(exList)")
                        if exList.isEmpty { // data가 비어있으면 doucument 삭제
                            emptyDocument(date: date, subject: subject)
                        } else { // 다시 저장(덮어쓰기)
                            firstSaveData(data: exList, date: date, subject: subject)
                        }
                    }
                }
            }
        }
    }
    
    private static func emptyDocument(date: String, subject: PassthroughSubject<Bool, Never>) {
        let db = Firestore.firestore()
        let ref = db.collection("userData").document("saveExInfo").collection(configFirebase.UID).document(date)
        ref.delete { error in
            if let error = error {
                print("firebase delete document error: \(error.localizedDescription)")
                subject.send(false)
            } else {
                print("Delete Empty Document Success")
                subject.send(true)
            }
        }
    }
    
    // 서버에 완료 운동 저장(랭킹에 직접적으로 반영되는 것이기 때문에 신고 시 확인 + 악용 유저 차단을 위해 별도로 삭제 처리 안 함 / 탈퇴 시 삭제)
    static func saveDoneEx(exName: String, set: Int16? = nil, weight: Float? = nil, count: Int16? = nil,
                           distance: Double? = nil, maxSpeed: Double? = nil, avgSpeed: Double? = nil,
                           time: Int64, date: String) { // time == sec(초), maxSpee, avgSpeed == m/s
        let exinfo: [String: Any] = [
            "exName": exName, "set": "\(set ?? 0) 세트", "weight": "\(weight ?? 0) kg", "count": "\(count ?? 0) 회",
            "distance": "\(distance ?? 0) m", "maxSpeed": "\(maxSpeed ?? 0) m/s", "avgSpeed": "\(avgSpeed ?? 0) m/s",
            "time": "\(time) 초", "date": date
        ]
        let db = Firestore.firestore()
        db.collection("userData").document("doneExInfo").collection(UID).document(date).getDocument { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.saveDoneEx", descriptions: error.localizedDescription)
                return
            } else {
                guard let snapshot = snapshot else {
                    configFirebase.errorReport(type: "configFirebase.saveDoneEx", descriptions: "snapshot = nil")
                    return
                }
                if snapshot.exists { // 파일이 존재 할 때, 저장된 값과 합해서 다시 저장
                    guard let data = snapshot.data() as? [String: [Any]] else {
                        print("error: dataType error")
                        configFirebase.errorReport(type: "configFirebase.saveDoneEx", descriptions: "snapshot.data() Type error")
                        return
                    }
                    if var info = data["info"] {
                        info.append(exinfo)
                        self.mergeDoneData(data: info, date: date)
                    }
                } else {
                    self.firstSaveDoneData(data: [exinfo], date: date)
                }
            }
        }
    }
    
    // 서버에 운동 저장
    static func saveEx(exName: String, time: Int64, uuid: String, date: String) {
        let exinfo: [String: Any] = ["exName": exName, "time": time, "uuid": uuid]
        let db = Firestore.firestore()
        db.collection("userData").document("saveExInfo").collection(UID).document(date).getDocument { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.saveEx", descriptions: error.localizedDescription)
                return
            } else {
                guard let snapshot = snapshot else {
                    configFirebase.errorReport(type: "configFirebase.saveEx", descriptions: "snapshot = nil")
                    return
                }
                if snapshot.exists { // 파일이 존재 할 때, 저장된 값과 합해서 다시 저장
                    guard let data = snapshot.data() as? [String: [Any]] else {
                        print("error: dataType error")
                        configFirebase.errorReport(type: "configFirebase.saveEx", descriptions: "snapshot.data() Type error")
                        return
                    }
                    if var info = data["info"] {
                        info.append(exinfo)
                        self.mergeAndSave(data: info, date: date)
                    }
                } else {
                    self.firstSaveData(data: [exinfo], date: date)
                }
            }
        }
    }
    
    private static func firstSaveData(data: [[String : Any]], date: String, subject: PassthroughSubject<Bool, Never>? = nil) {
        let db = Firestore.firestore()
        db.collection("userData").document("saveExInfo").collection(UID).document(date).setData(["info": data]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.firstSaveData", descriptions: error.localizedDescription)
                subject?.send(false)
            } else {
                print("Success: 파일 저장 완료")
                subject?.send(true)
            }
        }
    }
    
    private static func mergeAndSave(data: [Any], date: String, subject: PassthroughSubject<Bool, Never>? = nil) {
        let db = Firestore.firestore()
        db.collection("userData").document("saveExInfo").collection(UID).document(date).setData(["info": data]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.mergeAndSave", descriptions: error.localizedDescription)
                subject?.send(false)
            } else {
                print("Success: 파일 저장 완료")
                subject?.send(true)
            }
        }
    }
    
    private static func firstSaveDoneData(data: [[String : Any]], date: String, subject: PassthroughSubject<Bool, Never>? = nil) {
        let db = Firestore.firestore()
        db.collection("userData").document("doneExInfo").collection(UID).document(date).setData(["info": data]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.firstSaveDoneData", descriptions: error.localizedDescription)
                subject?.send(false)
            } else {
                print("Success: 파일 저장 완료")
                subject?.send(true)
            }
        }
    }
    
    private static func mergeDoneData(data: [Any], date: String, subject: PassthroughSubject<Bool, Never>? = nil) {
        let db = Firestore.firestore()
        db.collection("userData").document("doneExInfo").collection(UID).document(date).setData(["info": data]) { error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "configFirebase.mergeDoneData", descriptions: error.localizedDescription)
                subject?.send(false)
            } else {
                print("Success: 파일 저장 완료")
                subject?.send(true)
            }
        }
    }
}
