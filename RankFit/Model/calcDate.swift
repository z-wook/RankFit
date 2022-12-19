//
//  calcDate.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/18.
//

import Foundation

final class calcDate {
    
    func currentDate() -> String { // 현재 날짜 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let now = Date()
        return formatter.string(from: now)
    }
    
    func after30days() -> String { // 30일 후 날짜 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        //현재 날짜를 기준으로 매개변수로 전달된 TimeInterval만큼 후의 시간(-값을 전달할 경우 전의 시간)
        let after30days = Date(timeIntervalSinceNow: 86400 * 30) // 86400 = 1day
        return formatter.string(from: after30days)
    }
    
    func currentYear() -> String { // 현재 연도 반환
        let formatter = DateFormatter()
        let now = Date()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: now)
    }
}
