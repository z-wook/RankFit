//
//  HomeViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/06.
//

import Foundation

final class HomeViewModel {
    
    func getPercentList() -> [Double] {
        let dates = getDate()
        var percentList: [Double] = []

        for i in dates {
            let exInfoList = ConfigDataStore.fetchCoreData(date: i)

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
        
        // 과거
        if num != 6 {
            for i in (1...6-num).reversed() {
                let calc = Date(timeIntervalSinceNow: TimeInterval(-86400 * i))
                date_string = dateFormatter.string(from: calc)
                dateList.append(date_string)
            }
        }
        // 오늘
        date_string = dateFormatter.string(from: nowDate)
        dateList.append(date_string)
        
        // 미래
        if num != 0 {
            for i in 1...num {
                let calc = Date(timeIntervalSinceNow: TimeInterval(86400 * i))
                date_string = dateFormatter.string(from: calc)
                dateList.append(date_string)
            }
        }
        return dateList
    }
    
    func getDate() -> [String] {
        switch getWeek() {
        case "월요일":
            return 요일_날짜(num: 6)
        case "화요일":
            return 요일_날짜(num: 5)
        case "수요일":
            return 요일_날짜(num: 4)
        case "목요일":
            return 요일_날짜(num: 3)
        case "금요일":
            return 요일_날짜(num: 2)
        case "토요일":
            return 요일_날짜(num: 1)
        case "일요일":
            return 요일_날짜(num: 0)
        default:
            return []
        }
    }
}
