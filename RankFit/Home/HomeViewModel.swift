//
//  HomeViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/06.
//

import Foundation

final class HomeViewModel {
    let numDaysInWeek = 7

    func getPercentList() -> [Double] {
        let dates = getDate()
        var percentList: [Double] = []

        for i in dates {
            let exInfoList = ExerciseCoreData.fetchCoreData(date: i)

            let checkExList: [Int] = exInfoList.map { info in
                if let anaerobicEx = info as? anaerobicExerciseInfo {
                    if anaerobicEx.done {
                        return 1
                    } else {
                        return 0
                    }
                } else {
                    let aerobicEx = info as! aerobicExerciseInfo
                    if aerobicEx.done {
                        return 1
                    } else {
                        return 0
                    }
                }
            }
            // 해당 날짜의 완료/미완료 운동 가져오기
            if checkExList.count == 0 {
                percentList.append(0) // 저장한 운동이 없으면 배열에 0% append
            } else { // 저장한 운동이 있을 때
                let ex_count = Double(checkExList.count)
                let done_element = checkExList.filter { $0 == 1 } // 완료 = 1, 완료 개수
                let done_count = Double(done_element.count)
                
                let percent = (done_count / ex_count) * 100 // 완료 운동 백분율(%)
                let round_percent = round(percent * 10) / 10
                percentList.append(round_percent)
            }
        }
        return percentList
    }
    
    // Improved the code by ChatGPT!
    func getDayOfWeekInKorean() -> String {
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko")
        dateFormatter.dateFormat = "E요일"
        let dayOfWeek = dateFormatter.string(from: nowDate)
        return dayOfWeek
    }

    func getDatesForNumDaysBeforeAndAfterToday(daysBefore: Int, daysAfter: Int) -> [String] {
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
}
