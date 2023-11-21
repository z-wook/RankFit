//
//  OptionDetailViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/18.
//

import Foundation
import Alamofire
import Combine

final class OptionDetailViewModel {
    
    let infoSubject = CurrentValueSubject<[AnyHashable]?, Never>(nil)
    
    func getDetailExInfo(nickName: String) {
        let url = "http://mate.gabia.io/info.php"
        let parameters: Parameters = [
            "userNickname": nickName,
            "start": TimeStamp.getStart_OR_End_Timestamp(start_or_end: "start"),
            "end": TimeStamp.getStart_OR_End_Timestamp(start_or_end: "end")
        ]
        AF.request(url, method: .post, parameters: parameters)
            .responseDecodable(of: OptionDetailInfo.self) { response in
                if let info = response.value {
                    let list = self.sortedList(info: info)
                    print("list: \(list)")
                    self.infoSubject.send(list)
                } else {
                    print("info == nil")
                    configFirebase.errorReport(type: "OptionDetailVM.getDetailExInfo", descriptions: "info == nil", server: response.debugDescription)
                    self.infoSubject.send([])
                }
            }
    }
    
    private func sortedList(info: OptionDetailInfo) -> [AnyHashable] {
        var list: [AnyHashable] = []
        list.append(info.Anaerobics)
        list.append(info.Aerobics)
        return list
    }
    
    func getUserExercises(data: [AnyHashable], date: String) -> [AnyHashable] {
        var list: [AnyHashable] = []
        let start = TimeStamp.get_Timestamp(date_str: date, start_OR_end: "start")
        let end = TimeStamp.get_Timestamp(date_str: date, start_OR_end: "end")
        
        for i in data {
            guard let anaero = i as? [anaerobic] else {
                let aero = i as! [aerobic]
                for i in aero {
                    if i.Date >= start && i.Date <= end {
                        list.append(i)
                    }
                }
                continue
            }
            for i in anaero {
                if i.Date >= start && i.Date <= end {
                    list.append(i)
                }
            }
        }
        return list
    }
}
