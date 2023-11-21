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
//    enum Error: String {
//        case lost = "URLSessionTask failed with error: The network connection was lost."
//        case time = "URLSessionTask failed with error: The request timed out."
//    }
    func getWeeklyRank(subject: CurrentValueSubject<[WeeklyRank]?, Never>) {
        Task {
            do {
                let data = try await requestToServer()
                getWeeklyRankListData(subject: subject, Data: data)
            } catch {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "WeeklyRankVM.getWeeklyRank", descriptions: error.localizedDescription, server: error.asAFError.debugDescription)
            }
        }
    }
    
    private func requestToServer() async throws -> weekRank {
        var retryCount = 0
        while retryCount < 3 {
            do {
                return try await AF.request("http://mate.gabia.io/weekEXrank.php", method: .post).serializingDecodable().value
            } catch {
                print("error: \(error.localizedDescription)")
                retryCount += 1
                if retryCount > 3 {
                    throw error
                }
            }
        }
        throw NSError(domain: "MaxRetryCountExceeded", code: 0)
    }
    
    private func getWeeklyRankListData(subject: CurrentValueSubject<[WeeklyRank]?, Never>, Data: weekRank) {
        let objectList = Data.All
        let weeklyRankList = objectList.map {
            WeeklyRank(rank: $0["Rank"] ?? "", exercise: $0["Exercise"] ?? "")
        }
        subject.send(weeklyRankList)
    }
}
