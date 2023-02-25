//
//  receiveOptionRankInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/05.
//

import Foundation

struct OptionRankInfo: Hashable {
    let Nickname: String
    let Ranking: String
    let Score: String
}

struct OpRankInfo: Codable {
    let All: [[String: String]]
    let My: [String: String]
}

struct anaerobic: Codable, Hashable {
    var Exercise: String
    var Date: Int
    var Set: Int
    var Weight: Float
    var Count: Int
    var Time: Double
}

struct aerobic: Codable, Hashable {
    var Exercise: String
    var Date: Int
    var Distance: Double
    var Time: Int
}

class OptionDetailInfo: Codable {
    var Anaerobics: [anaerobic]
    var Aerobics: [aerobic]
    
    init(Anaerobics: [anaerobic], Aerobics: [aerobic]) {
        self.Anaerobics = Anaerobics
        self.Aerobics = Aerobics
    }
}

extension OptionDetailInfo: Hashable {
    static func == (lhs: OptionDetailInfo, rhs: OptionDetailInfo) -> Bool {
        return lhs.Anaerobics == rhs.Anaerobics && lhs.Aerobics == rhs.Aerobics
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(Anaerobics)
        hasher.combine(Aerobics)
    }
}
