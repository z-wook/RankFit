//
//  getDateString.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/15.
//

import Foundation

final class getDateString {
    
    private let numDaysInWeek = 7
    
    static func getCurrentDate_Time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        let currentDateString = dateFormatter.string(from: Date())
        return currentDateString
    }
    
    // Improved the code by ChatGPT!
    private func getDayOfWeekInKorean() -> String {
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko")
        dateFormatter.dateFormat = "E요일"
        let dayOfWeek = dateFormatter.string(from: nowDate)
        return dayOfWeek
    }

    private func getDatesForNumDaysBeforeAndAfterToday(daysBefore: Int, daysAfter: Int) -> [String] {
        var dates: [String] = []
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let calendar = Calendar.current
        
        // Past dates
        if daysBefore != 0 {
            for i in (1...daysBefore).reversed() {
                let pastDate = calendar.date(byAdding: .day, value: -i, to: nowDate)!
                let dateString = dateFormatter.string(from: pastDate)
                dates.append(dateString)
            }
        }
        
        // Today's date
        let todayString = dateFormatter.string(from: nowDate)
        dates.append(todayString)
        
        // Future dates
        if daysAfter != 0 {
            for i in 1...daysAfter {
                let futureDate = calendar.date(byAdding: .day, value: i, to: nowDate)!
                let dateString = dateFormatter.string(from: futureDate)
                dates.append(dateString)
            }
        }
        return dates
    }
    
    func getDate() -> [String] {
        switch getDayOfWeekInKorean() {
        case "월요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 7, daysAfter: 6)
        case "화요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 6, daysAfter: 5)
        case "수요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 5, daysAfter: 4)
        case "목요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 4, daysAfter: 3)
        case "금요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 3, daysAfter: 2)
        case "토요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 2, daysAfter: 1)
        case "일요일":
            return getDatesForNumDaysBeforeAndAfterToday(daysBefore: numDaysInWeek - 1, daysAfter: 0)
        default:
            return []
        }
    }
    
    func getMonthAgo() -> [String] { // 한달 치 날짜 구하기(메인 radarChart에 사용)
        return getDatesForNumDaysBeforeAndAfterToday(daysBefore: 29, daysAfter: 0)
    }
}
