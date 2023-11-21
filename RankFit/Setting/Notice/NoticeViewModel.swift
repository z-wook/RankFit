//
//  NoticeViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/26.
//

import Foundation
import Alamofire
import Combine

struct Notification: Codable, Hashable {
    let Notice: [[String: String]]
}

class notification: Hashable {
    let title: String
    let content: String
    let register_day: String
    
    init(title: String, content: String, register_day: String) {
        self.title = title
        self.content = content
        self.register_day = register_day
    }
    
    static func == (lhs: notification, rhs: notification) -> Bool {
        return lhs.title == rhs.title && lhs.content == rhs.content && lhs.register_day == rhs.register_day
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(content)
        hasher.combine(register_day)
    }
}

final class NoticeViewModel {
    func getNotice(subject: CurrentValueSubject<[notification]?, Never>) {
        AF.request("http://mate.gabia.io/notice.php", method: .post).responseDecodable(of: Notification.self) { response in
            switch response.result {
            case .success(let object):
                var list: [notification] = []
                let objectList = object.Notice
                for i in objectList {
                    let notiInfo = notification(title: i["title"] ?? "", content: i["content"] ?? "", register_day: i["register_day"] ?? "")
                    list.append(notiInfo)
                    if i == objectList.last {
                        subject.send(list)
                        return
                    }
                }
                
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "NoticeViewModel.getNotice", descriptions: error.localizedDescription, server: response.debugDescription)
            }
        }
    }
}
