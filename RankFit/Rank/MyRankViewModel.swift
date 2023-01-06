//
//  MyRankViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/01.
//

import Foundation

final class MyRankViewModel {
    
    func getDoneEx(dates: [String]) -> [String] {
        var resultList: [String] = []
        
        for i in dates {
            let exInfoList = ConfigDataStore.fetchCoreData(date: i)
            let doneExList: [String] = exInfoList.map { info in
                if let anaerobicEx = info as? anaerobicExerciseInfo {
                    if anaerobicEx.done {
                        return anaerobicEx.exercise
                    }
                } else {
                    let aerobicEx = info as! aerobicExerciseInfo
                    if aerobicEx.done {
                        return aerobicEx.exercise
                    }
                }
                return ""
            }
            resultList += doneExList
        }
        return resultList
    }
    
    func getSortedExList() -> [String] {
        let Dates = getDate()
        
        let doneExList = getDoneEx(dates: Dates)
        let filteredEx = doneExList.filter { exName in
            if exName != "" {
                return true
            } else {
                return false
            }
        }
        let setList = Set(filteredEx)
        let sortedList = setList.sorted { prev, next in
            return prev < next
        }
        return sortedList
    }
    
    func getWeek() -> String {
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko")
        dateFormatter.dateFormat = "E요일"
        let date_string = dateFormatter.string(from: nowDate)
        return date_string
    }
    
    func 요일_날짜(num: Int) -> [String] {
        var dateList: [String] = []
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        var date_string: String = ""
        dateFormatter.locale = Locale(identifier: "ko")
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        if(num == 0) {
            date_string = dateFormatter.string(from: nowDate)
            dateList.append(date_string)
        }
        
        if(num != 0) {
            for i in (1...num).reversed() {
                let calc = Date(timeIntervalSinceNow: TimeInterval(-86400 * i))
                date_string = dateFormatter.string(from: calc)
                dateList.append(date_string)
            }
            date_string = dateFormatter.string(from: nowDate)
            dateList.append(date_string)
        }
        return dateList
    }
    
    func getDate() -> [String] {
        switch getWeek() {
        case "월요일":
            return 요일_날짜(num: 0)
        case "화요일":
            return 요일_날짜(num: 1)
        case "수요일":
            return 요일_날짜(num: 2)
        case "목요일":
            return 요일_날짜(num: 3)
        case "금요일":
            return 요일_날짜(num: 4)
        case "토요일":
            return 요일_날짜(num: 5)
        case "일요일":
            return 요일_날짜(num: 6)
        default:
            return []
        }
    }
}

