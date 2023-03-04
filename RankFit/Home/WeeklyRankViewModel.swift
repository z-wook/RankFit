//
//  WeeklyRankViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/25.
//

import Foundation
import Alamofire
import Combine

struct weekRank: Codable, Hashable {
    let All: [[String: String]]
}

class WeeklyRank: Hashable {
    var rank: String
    var exercise: String
    
    init(rank: String, exercise: String) {
        self.rank = rank
        self.exercise = exercise
    }
    
    static func == (lhs: WeeklyRank, rhs: WeeklyRank) -> Bool {
        return lhs.rank == rhs.rank && lhs.exercise == rhs.exercise
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rank)
        hasher.combine(exercise)
    }
}

final class WeeklyRankViewModel {
    func getWeeklyRank(subject: CurrentValueSubject<[WeeklyRank]?, Never>) {
        AF.request("http://rankfit.site/weekEXrank.php", method: .post).responseDecodable(of: weekRank.self) { response in
//            print("response: \(response.debugDescription)")
            print("response: \(response)")
            switch response.result {
            case .success(let object):
                let objectList = object.All
                var list: [WeeklyRank] = []
                for i in objectList {
                    list.append(WeeklyRank(rank: i["Rank"] ?? "", exercise: i["Exercise"] ?? ""))
                    if i == objectList.last {
                        subject.send(list)
                        return
                    }
                }
                subject.send(list)
                
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "WeeklyRankViewModel.getWeeklyRank", descriptions: error.localizedDescription, server: response.debugDescription)
            }
        }
    }
}
