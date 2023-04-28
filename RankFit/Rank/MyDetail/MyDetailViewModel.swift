//
//  MyDetailViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/02.
//

import Foundation
import Combine
import Alamofire

final class MyDetailViewModel {
    
    let receiveSubject = CurrentValueSubject<[OptionRankInfo]?, Never>(nil)
    
    func getMyDetailRank(info: [String : String]) {
        let url = "http://rankfit.site/ExerciseRank.php"
        var infoList: [OptionRankInfo] = [] // MyRank이지만 OptionRankInfo와 같은 형식의 구제체이므로 재활용 한것임
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth!)
        let start_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start")
        let end_Timestamp = TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        
        let parameters: Parameters = [
            "userID": saveUserData.getKeychainStringValue(forKey: .UID) ?? "정보없음",
            "userSex": saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0,
            "userAge": age,
            "eng": info["tName"]!,
            "start": start_Timestamp,
            "end": end_Timestamp
        ]
        print("params: \(parameters)")
        
        AF.request(url, method: .post, parameters: parameters).responseDecodable(of: OpRankInfo.self) { response in
            print("response: \(response)")
            switch response.result {
            case .success(let object):
                let allInfo = object.All
                let myInfo = object.My
                
                let myInformation = OptionRankInfo(Nickname: "나의 랭킹", Ranking: myInfo["My_Ranking"]!, Score: myInfo["My_Score"]!)
                infoList.append(myInformation)
                
                for i in allInfo {
                    let allInformation = OptionRankInfo(Nickname: i["Nickname"]!, Ranking: i["Ranking"]!, Score: i["Score"]!)
                    infoList.append(allInformation)
                }
                self.receiveSubject.send(infoList)
                
            case .failure(let error):
                print("error: " + error.localizedDescription)
                configFirebase.errorReport(type: "MyDetailVM.getMyDetailRank", descriptions: error.localizedDescription, server: response.debugDescription)
                self.receiveSubject.send([])
            }
        }
    }
}
