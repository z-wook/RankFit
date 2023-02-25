//
//  ReturnToRankFit.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/21.
//

import Foundation
import Combine
import Alamofire

final class ReturnToRankFit {
    
    let imgNameState = PassthroughSubject<[String], Never>()
    let downloadState = PassthroughSubject<String, Never>()
    let infoSubject = CurrentValueSubject<[AnyHashable]?, Never>(nil)
    var finalSubject: PassthroughSubject<Bool, Never>!
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    private func bind() {
        imgNameState.receive(on: RunLoop.main).sink { imgNameList in
            // 서버에서 사진 다운 & 로컬에 사진 저장
            configFirebase.downloadImage(imgNameList: imgNameList, subject: self.downloadState)
        }.store(in: &subscriptions)
        
        downloadState.receive(on: RunLoop.main).sink { imgName in
            let timeStamp: Int64!
            // coreData에 파일 정보 저장
            if imgName != "false" {
                if imgName == "profileImage.jpeg" { // 프로필 사진이면 다르게 저장
                    timeStamp = Int64(TimeStamp.getCurrentTimestamp())
                } else {
                    // 여기서 saveTime을 파일 앞에 이름 따서 만들기
                    let startIndex = imgName.index(imgName.startIndex, offsetBy: 0) // 시작 인덱스
                    let endIndex = imgName.index(imgName.startIndex, offsetBy: 10) // 끝 인덱스
                    let sliced_str = imgName[startIndex ..< endIndex]
                    timeStamp = Int64(sliced_str) ?? Int64(TimeStamp.getCurrentTimestamp())
                }
                let photoinfo = PhotoInfomation(imageName: imgName, saveTime: timeStamp)
                let result = PhotoCoreData.saveCoreData(info: photoinfo)
                if result == false { // Firebase에서 일부 사진 저장 실패하더라도 에러 보고만 하고 계속 진행하기
                    print("coreData에 저장 못함")
                    configFirebase.errorReport(type: "DiaryVC.bind/downloadState", descriptions: "CoerData에 저장 못함")
                    // doucument에서 file 삭제
                    configLocalStorage.deleteImageFromDocumentDirectory(imageName: imgName)
                }
            } else {
                print("로컬에 저장 못함")
                configFirebase.errorReport(type: "DiaryVC.bind/downloadState", descriptions: "Local에 저장 못함")
            }
        }.store(in: &subscriptions)
        
        infoSubject.receive(on: RunLoop.main).sink { info in
            guard let info = info else { return }
            self.saveCoreData(infoList: info)
        }.store(in: &subscriptions)
    }
    
    func initiate(nickName: String, Subject: PassthroughSubject<Bool, Never>) {
        finalSubject = Subject
        // Firebase에서 사진 이름 가져오기
        configFirebase.getImgNameFromFirebase(subject: imgNameState)
        // 서버에서 완료 운동 가져오기
        getDetailExInfo(nickName: nickName)
        
        // 토큰 값 Firebase로 전송
        let token = saveUserData.getKeychainStringValue(forKey: .Token) ?? "Token == nil"
        configFirebase.updateToken(Token: token)
    }
}

extension ReturnToRankFit {
    private func saveCoreData(infoList: [AnyHashable]) {
        for info in infoList {
            if let anaerobicList = info as? [anaerobic] {
                for anaerobic in anaerobicList {
                    let exercise = anaerobic.Exercise
                    let saveTime = anaerobic.Date       // 운동 완료한 Timestamp
                    let set = anaerobic.Set
                    let weight = anaerobic.Weight
                    let count = anaerobic.Count
                    let time = anaerobic.Time           // 운동 소요 시간
                    let tableName = getTableName(exName: exercise)
                    let date = TimeStamp.convertTimeStampToDate(timestamp: saveTime, For: "returnUser") // 캘린더에 저장할 날짜
                    let exInfo = anaerobicExerciseInfo(exercise: exercise, table_Name: tableName, date: date, set: Int16(set),
                                                       weight: weight, count: Int16(count), exTime: time, saveTime: Int64(saveTime), done: true)
                    let save = ExerciseCoreData.saveCoreData(info: exInfo)
                    if save == false { // CoreData 저장 실패
                        configFirebase.errorReport(type: "ReturnToRankFit.saveCoreData.anaerobic", descriptions: "CoreData에 운동 저장 실패")
                    }
                }
            } else { // aerobic
                let aerobicList = info as! [aerobic]
                for aerobic in aerobicList {
                    let exercise = aerobic.Exercise
                    let saveTime = aerobic.Date         // 운동 완료한 Timestamp
                    let distance = aerobic.Distance
                    let time = aerobic.Time
                    let tableName = getTableName(exName: exercise)
                    let date = TimeStamp.convertTimeStampToDate(timestamp: saveTime, For: "returnUser") // 캘린더에 저장할 날짜
                    let exInfo = aerobicExerciseInfo(exercise: exercise, table_Name: tableName, date: date,
                                                     time: Int16(time), distance: distance, saveTime: Int64(saveTime), done: true)
                    let save = ExerciseCoreData.saveCoreData(info: exInfo)
                    if save == false { // CoreData 저장 실패
                        configFirebase.errorReport(type: "ReturnToRankFit.saveCoreData.aerobic", descriptions: "CoreData에 운동 저장 실패")
                    }
                }
            }
        }
        finalSubject.send(true)
    }
    
    private func getTableName(exName: String) -> String {
        for i in ExerciseInfo.ExerciseInfoList {
            if i.exerciseName == exName {
                return i.table_name
            }
        }
        return "nil"
    }
    
    private func getDetailExInfo(nickName: String) {
        let url = "http://rankfit.site/info.php"
        let parameters: Parameters = [
            "userNickname": nickName,
            "start": TimeStamp.forReturnUserTimestamp(start_or_end: "start"),
            "end": TimeStamp.forReturnUserTimestamp(start_or_end: "end")
        ]
        AF.request(url, method: .post, parameters: parameters)
            .responseDecodable(of: OptionDetailInfo.self) { response in
                if let info = response.value {
                    let list = self.sortedList(info: info)
                    self.infoSubject.send(list)
                } else {
                    print("info == nil")
                    configFirebase.errorReport(type: "OptionDetailVM.getDetailExInfo", descriptions: "info == nil", server: response.debugDescription)
                    self.infoSubject.send([])
                }
            }
    }
    
    private func sortedList(info: OptionDetailInfo) -> [AnyHashable] {
        var list: [AnyHashable] = []
        list.append(info.Anaerobics)
        list.append(info.Aerobics)
        return list
    }
    
    private func getUserExercises(data: [AnyHashable], date: String) -> [AnyHashable] {
        var list: [AnyHashable] = []
        let start = TimeStamp.get_Timestamp(date_str: date, start_OR_end: "start")
        let end = TimeStamp.get_Timestamp(date_str: date, start_OR_end: "end")
        
        for i in data {
            guard let anaero = i as? [anaerobic] else {
                let aero = i as! [aerobic]
                for i in aero {
                    if i.Date >= start && i.Date <= end {
                        list.append(i)
                    }
                }
                continue
            }
            for i in anaero {
                if i.Date >= start && i.Date <= end {
                    list.append(i)
                }
            }
        }
        return list
    }
}
