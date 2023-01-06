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
    
    let optionSubject = PassthroughSubject<[receiveRankInfo], Never>()
    let savedUserInfo = getUserInfo()
    
    func getAgeRank() {
        let url = "http://rankfit.site/AgeRank.php"
        var infoList: [receiveRankInfo] = []
        let parameters: Parameters = [
            "userID": getUserInfo().getUserID(),
            "userAge": getUserInfo().getAge()
        ]

        AF.request(url, method: .post, parameters: parameters).responseJSON {
            response in
            switch response.result {
            case .success(let values):
                let data = values as! NSDictionary
                print("data: \(data)")
                
                let myRank = data["My_Ranking"] as! String
                let myScore = data["My_Score"] as! String
                let myInfo = receiveRankInfo(Nickname: "나의 랭킹", Ranking: myRank, Score: myScore)
                infoList.append(myInfo)
                
                let rankCount = data["count"] as! Int
                for i in 0...rankCount {
                    let valueInfo = data.value(forKey: "\(i)") as! NSDictionary
                    
                    let userInfo = receiveRankInfo(Nickname: "\(valueInfo["Nickname"] as! String)", Ranking: "\(valueInfo["Ranking"] as! String)", Score: "\(valueInfo["Score"] as! String)")
                    infoList.append(userInfo)
                }
                self.optionSubject.send(infoList)
                
            case .failure(let error):
                print("error!!!: \(error)")
                break;
            }
        }
    }
    
    
    
    
    func getGenderRank() {
        let url = "http://rankfit.site/SexRank.php"
        var infoList: [receiveRankInfo] = []
        let parameters: Parameters = [
            "userID": savedUserInfo.getUserID(),
            "userSex": savedUserInfo.getGender()
        ]
        
        AF.request(url, method: .post, parameters: parameters).responseJSON {
            response in
            switch response.result {
            case .success(let values):
                let data = values as! NSDictionary
                
                print("data: \(data)")
                let myRank = data["My_Ranking"] as! String
                let myScore = data["My_Score"] as! String
                let myInfo = receiveRankInfo(Nickname: "나의 랭킹", Ranking: myRank, Score: myScore)
                infoList.append(myInfo)
                
                let rankCount = data["count"] as! Int
                for i in 0...rankCount {
                    let valueInfo = data.value(forKey: "\(i)") as! NSDictionary
                    
                    let userInfo = receiveRankInfo(Nickname: "\(valueInfo["Nickname"] as! String)", Ranking: "\(valueInfo["Ranking"] as! String)", Score: "\(valueInfo["Score"] as! String)")
                    infoList.append(userInfo)
                    
//                    do {
//                        let data = try JSONSerialization.data(withJSONObject: values, options: .prettyPrinted)
//                        let userlists = try JSONDecoder().decode(userInfo.self, from: data)
//                        print("email : \(userlists.Nickname)")
//                        print("result : \(userlists.Ranking)")
//                        print("result : \(userlists.Score)")
//                    } catch {
//                        print("error!!!\(error)")
//                    }
                    
                }
                self.optionSubject.send(infoList)
                
            case .failure(let error):
                print("error!!!: \(error)")
                return
            }
        }
    }
    
    
    
    
}
