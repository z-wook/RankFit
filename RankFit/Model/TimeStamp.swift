//
//  TimeStamp.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/15.
//

import Foundation

final class TimeStamp {
    
    static private func six_months_ago_Timestamp() -> Int {
        let now = Date().timeIntervalSince1970 // 현재 타임스탬프
        let secondsInSixMonths: TimeInterval = 6 * 30 * 24 * 60 * 60 // 6개월에 해당하는 초 수
        let sixMonthsAgo = now - secondsInSixMonths // 약 6개월(180일) 전의 타임스탬프
        return Int(sixMonthsAgo)
    }
    
    // 복귀 유저를 위해 사용하는 Timestamp
    static func forReturnUserTimestamp(start_or_end type: String) -> Int {
        if type == "start" {
            let start = six_months_ago_Timestamp()
            return start
        } else if type == "end" {
            let end = getCurrentTimestamp()
            return end
        } else {
            return 0
        }
    }
    
    static func getStart_OR_End_Timestamp(start_or_end type: String) -> Int {
        let dates = getDateString().getDate()
        if type == "start" {
            let start = dates.first ?? ""
            let timestamp = TimeStamp.get_Timestamp(date_str: start, start_OR_end: type)
            return timestamp
        } else if type == "end" {
            let end = dates.last ?? ""
            let timestamp = TimeStamp.get_Timestamp(date_str: end, start_OR_end: type)
            return timestamp
        } else {
            return 0
        }
    }
    
    static func getCurrentTimestamp() -> Int {
        let timestamp = Int(Date().timeIntervalSince1970)
        return timestamp
    }
    
    static func getTimeInterval(now: Date, before: Date) -> Int {
        let timeInterval = now.timeIntervalSince(before)
        return Int(timeInterval)
    }
    
    static func get_Timestamp(date_str: String, start_OR_end: String) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        var date: Date!

        switch start_OR_end {
        case "start":
            date = dateFormatter.date(from: "\(date_str)-00:00:00")
        case "end":
            date = dateFormatter.date(from: "\(date_str)-23:59:59")
        default:
            date = dateFormatter.date(from: "\(date_str)-00:00:00")
        }
        let timestamp = Int(date!.timeIntervalSince1970)
        return timestamp
    }
    
    static func convertTimeStampToDate(timestamp: Int, For: String? = nil) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        if For == "returnUser" {
            dateFormatter.dateFormat = "yyyy-MM-dd"
        } else {
            dateFormatter.dateFormat = "yyyy-MM-ddHH:mm"
        }
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
