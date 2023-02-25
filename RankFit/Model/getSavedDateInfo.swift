//
//  getUserInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/19.
//

import Foundation

final class getSavedDateInfo {
    
    func getNickNameDate() -> String {
        guard let saved_id_date = UserDefaults.standard.string(forKey: "nick_date") else { return "-1" }
        return saved_id_date
    }
    
    func getAgeDate() -> String {
        guard let saved_age_date = UserDefaults.standard.string(forKey: "age_date") else { return "-1" }
        return saved_age_date
    }
    
    func getWeightDate() -> String {
        guard let saved_weight_date = UserDefaults.standard.string(forKey: "weight_date") else { return "-1" }
        return saved_weight_date
    }
}
