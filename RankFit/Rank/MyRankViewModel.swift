//
//  MyRankViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/01.
//

import Foundation
import Combine
import Alamofire

final class MyRankViewModel {
    
    let MySubject = CurrentValueSubject<[MyRankInfo]?, Never>([])
    let receiveSubject = PassthroughSubject<MyRankInfo?, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    var myRankList: [MyRankInfo] = []
    var count: Int!
    enum Error: String {
        case time = "URLSessionTask failed with error: 요청한 시간이 초과되었습니다."
    }
    
    init() {
        receiveSubject.receive(on: RunLoop.main).sink { result in
            guard result != nil else {
                self.MySubject.send(nil)
                self.myRankList.removeAll()
                return
            }
            if self.myRankList.count == self.count {
                // 순서대로 응답받는다는 보장이 없으므로 이름순으로 정렬 후 전송
                let sortedList = self.myRankList.sorted { prev, next in
                    prev.Exercise < next.Exercise
                }
                self.MySubject.send(sortedList)
                self.myRankList.removeAll()
            }
        }.store(in: &subscriptions)
    }
    
    func getMyRank() {
        let url = "http://rankfit.site/MyRank.php"
        let sortedList = getSortedExList()
        count = sortedList.count
        
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth!)
        let start_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start")
        let end_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        
        for i in 0...sortedList.count-1 {
            let parameters: Parameters = [
                "userID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음",
                "userSex": saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0,
                "userAge": age,
                "kor": sortedList[i]["exName"] ?? "",
                "eng": sortedList[i]["tName"] ?? "",
                "start": start_Timestamp,
                "end": end_Timestamp
            ]
            print("params: \(parameters)")
            
            AF.request(url, method: .post, parameters: parameters).responseDecodable(of: MyRankInfo.self) { response in
                print("response: \(response)")
                switch response.result {
                case .success(let object):
                    self.myRankList.append(object)
                    self.receiveSubject.send(object)
                    
                case .failure(let error):
                    let error = error.localizedDescription
                    print("error: \(error)")
                    if error == Error.time.rawValue { return }
                    else {
                        configFirebase.errorReport(type: "MyRankVM.getMyRank", descriptions: error, server: response.debugDescription)
                        self.receiveSubject.send(nil)
                    }
                }
            }
        }
    }
    
    private func getDoneEx(dates: [String]) -> [[String: String]] {
        var resultList: [[String: String]] = []
        
        for i in dates {
            let exInfoList = ExerciseCoreData.fetchCoreData(date: i)
            let doneExList: [[String: String]] = exInfoList.map { info in
                if let anaerobicEx = info as? anaerobicExerciseInfo {
                    if anaerobicEx.done {
                        return ["exName": anaerobicEx.exercise, "tName": anaerobicEx.tableName]
                    }
                } else {
                    let aerobicEx = info as! aerobicExerciseInfo
                    if aerobicEx.done {
                        return ["exName": aerobicEx.exercise, "tName": aerobicEx.tableName]
                    }
                }
                return [:]
            }
            resultList += doneExList
        }
        return resultList
    }
    
    func getSortedExList() -> [[String : String]] {
        let Dates = getDateString().getDate()
        let doneExList = getDoneEx(dates: Dates)
        let filteredEx = doneExList.filter { exName in
            if exName != [:] { return true }
            else { return false }
        }
        let setList = Set(filteredEx)
        let sortedList = setList.sorted { prev, next in
            return prev["exName"]! < next["exName"]!
        }
        return sortedList
    }
}
