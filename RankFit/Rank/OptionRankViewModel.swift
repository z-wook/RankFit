//
//  OptionRankViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/05.
//

import Foundation
import Alamofire
import Combine

final class OptionRankViewModel {
    
    let optionSubject = CurrentValueSubject<[OptionRankInfo]?, Never>([])
    var infoList: [OptionRankInfo] = []
    
    func getGenderRank() {
        let url = "http://rankfit.site/SexRank.php"
        let parameters: Parameters = [
            "userID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음",
            "userSex": saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0,
        ]
        sendServer(URL: url, params: parameters)
    }
    
    func getAgeRank() {
        let url = "http://rankfit.site/AgeRank.php"
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth!)
        
        let parameters: Parameters = [
            "userID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음",
            "userAge": age
        ]
        sendServer(URL: url, params: parameters)
    }
    
    func getCustomRank() {
        let url = "http://rankfit.site/CustomRank.php"
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth!)
        
        let parameters: Parameters = [
            "userID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음",
            "userSex": saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0,
            "userAge": age
        ]
        sendServer(URL: url, params: parameters)
    }
    
    func getRunningRank() {
        let url = "http://rankfit.site/runningRank.php"
        
        let parameters: Parameters = [
            "userID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음"
        ]
        sendServer(URL: url, params: parameters)
    }
    
    private func sendServer(URL: String, params: Parameters) {
        AF.request(URL, method: .post, parameters: params)
            .responseDecodable(of: OpRankInfo.self) { response in
                print("response: \(response)")
                switch response.result {
                case .success(let object):
                    let allInfo = object.All
                    let myInfo = object.My
                    
                    let myInformation = OptionRankInfo(Nickname: "나의 랭킹", Ranking: myInfo["My_Ranking"] ?? "", Score: myInfo["My_Score"] ?? "")
                    self.infoList.append(myInformation)
                    
                    for i in allInfo {
                        let allInformation = OptionRankInfo(Nickname: i["Nickname"] ?? "", Ranking: i["Ranking"] ?? "", Score: i["Score"] ?? "")
                        self.infoList.append(allInformation)
                    }
                    self.optionSubject.send(self.infoList)
                    self.infoList.removeAll() // 전송 후 초기화
                    
                case .failure(let error):
                    print("error: \(error.localizedDescription)")
                    configFirebase.errorReport(type: "OptionRankVM.sendServer", descriptions: error.localizedDescription, server: response.debugDescription)
                    self.optionSubject.send(nil)
                }
            }
    }
}
