//
//  getUserInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/19.
//

import Foundation

final class getUserInfo {
    
    func getUserID() -> String {
        let userID = UserDefaults.standard.string(forKey: "UserID")
        
        if let strUserID = userID {
            return strUserID
        } else { return "-1" }
    }
    
    func getEmail() -> String {
        let email = UserDefaults.standard.string(forKey: "Email")
        
        if let strEmail = email {
            return strEmail
        } else { return "-1" }
    }
    
    func getNickName() -> String {
        guard let nickNameObject = UserDefaults.standard.object(forKey: "NickName")
                as? [String : Any] else { return "-1" }
        
        if let NickName = nickNameObject["nickname"] {
            let strNickName = NickName as! String
            return strNickName
        } else { return "-1"}
    }
    
    func getNickNameDays() -> String {
        guard let nickNameObject = UserDefaults.standard.object(forKey: "NickName")
                as? [String : Any] else { return "-1" }
        
        if let NickNameDate = nickNameObject["date"] {
            let strNickNameDate = NickNameDate as! String
            return strNickNameDate
        } else { return "-1"}
    }
    
    func getWeight() -> Int {
        guard let weightObject = UserDefaults.standard.object(forKey: "Weight")
                as? [String : Any] else { return -1 }
        
        if let weight = weightObject["weight"] {
            let intWeight = weight as! Int
            return intWeight
        } else { return -1 }
    }
    
    func getWeightDay() -> String {
        guard let weightObject = UserDefaults.standard.object(forKey: "Weight")
                as? [String : Any] else { return "-1" }
        
        if let WeightDate = weightObject["date"] {
            let strWeightDate = WeightDate as! String
            return strWeightDate
        } else { return "-1" }
    }
    
    func getGender() -> Int {
        let gender = UserDefaults.standard.integer(forKey: "Gender")
        return gender
    }
    
    func getAge() -> Int {
        guard let ageObject = UserDefaults.standard.object(forKey: "Age")
                as? [String : Any] else { return -1 }
        
        if let age = ageObject["age"] {
            let intAge = age as! Int
            return intAge
        } else { return -1 }
    }
    
    func getAgeYear() -> String {
        guard let ageObject = UserDefaults.standard.object(forKey: "Age")
                as? [String : Any] else { return "-1" }
        
        if let year = ageObject["year"] {
            let strYaer = year as! String
            return strYaer
        } else { return "-1"}
    }
    
}
