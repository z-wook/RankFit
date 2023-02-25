//
//  SlangFilter.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/08.
//

import Foundation

final class SlangFilter {
    
    private let slangList = [
        "시발", "시1발", "시2발",
        "개새끼", "개1새끼", "개2새끼",
        "지랄", "지1랄", "지2랄",
        "보지", "보1지", "보2지", "보짓물",
        "자지", "자1지", "자2지",
        "섹스", "섹1스", "섹2스",
        "병신", "병1신", "병2신",
        "애미", "애비",
        "강간", "몰카", "자위", "성기", "포르노", "좆", "폰섹",
        "야동", "애무", "오르가즘", "멜섭", "멜돔", "팸섭", "팸돔", "게이", "레즈", "정액", "귀두", "유두",
        "자살", "테러", "살인", "폭행",
        "fuck", "porn", "sex"
    ]
    
    func nickNameFilter(nickName: String) -> Bool { // 닉네임 통과 = true, 불통과 = false
        let lowStr = nickName.lowercased()
        
        for slang in slangList {
            let strCheck = lowStr.contains(slang)
            if strCheck {
                return false
            }
        }
        return true
    }
}
