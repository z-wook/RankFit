//
//  calcDate.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/18.
//

import Foundation

final class calcDate {
    
    let formatter = DateFormatter()
    let now = Date()

    init() {
        formatter.dateFormat = "yyyy-MM-dd"
    }
    
    func currentDate() -> String { // 현재 날짜 반환
        return formatter.string(from: now)
    }
    
    func after1Day() -> String {
        let after1day = Date(timeIntervalSinceNow: 86400) // 86400 = 1day
        return formatter.string(from: after1day)
    }
    
    func after30days() -> String { // 30일 후 날짜 반환
        //현재 날짜를 기준으로 매개변수로 전달된 TimeInterval만큼 후의 시간(-값을 전달할 경우 전의 시간)
        let after30days = Date(timeIntervalSinceNow: 86400 * 30) // 86400 = 1day
        return formatter.string(from: after30days)
    }
    
    func currentYear() -> String { // 현재 연도 반환
        formatter.dateFormat = "yyyy"
        return formatter.string(from: now)
    }
    
    func nextYear() -> String {
        formatter.dateFormat = "yyyy"
        let strYear = formatter.string(from: now)
        let intYear = Int(strYear) ?? -1
        let nextYear = intYear + 1
        return "\(nextYear)"
    }
    
    func getAge(BDay: String) -> Int {
        let birthdayDate = formatter.date(from: BDay)!
        let currentDate = Date()
        let ageComponents = Calendar.current.dateComponents([.year], from: birthdayDate, to: currentDate)
        let age = ageComponents.year!
        return age
    }
}
