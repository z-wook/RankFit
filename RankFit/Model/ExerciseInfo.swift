//
//  ExerciseInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation

struct ExerciseInfo: Codable, Hashable {
    
    let exerciseName: String
    let group: Int
}

extension ExerciseInfo {
    // group1 = Anaerobic, group2 = Anaerobic(세트, 개수만 필요한 운동), group3 = Aerobic
    static let ExerciseInfoList: [ExerciseInfo] = [
        ExerciseInfo(exerciseName: "숄더 프레스", group: 1),
        ExerciseInfo(exerciseName: "랫 풀 다운", group: 1),
        ExerciseInfo(exerciseName: "벤치 프레스", group: 1),
        ExerciseInfo(exerciseName: "케이블 로우", group: 1),
        ExerciseInfo(exerciseName: "딥스", group: 1),
        ExerciseInfo(exerciseName: "디클라인 벤치 프레스", group: 1),
        ExerciseInfo(exerciseName: "트라이셉스 푸시 다운", group: 1),
        ExerciseInfo(exerciseName: "데드리프트", group: 1),
        ExerciseInfo(exerciseName: "슈러그", group: 1),
        ExerciseInfo(exerciseName: "스쿼트", group: 2),
        ExerciseInfo(exerciseName: "레그 프레스", group: 1),
        ExerciseInfo(exerciseName: "레그 익스텐션", group: 1),
        ExerciseInfo(exerciseName: "런지", group: 2),
        ExerciseInfo(exerciseName: "백 익스텐션", group: 1),
        ExerciseInfo(exerciseName: "윗몸 일으키기", group: 2),
        ExerciseInfo(exerciseName: "아놀드 프레스", group: 1),
        ExerciseInfo(exerciseName: "바벨 로우", group: 1),
        ExerciseInfo(exerciseName: "풀업", group: 1),
        ExerciseInfo(exerciseName: "덤벨 로우", group: 1),
        ExerciseInfo(exerciseName: "플랭크", group: 2),
        ExerciseInfo(exerciseName: "크런치", group: 1),
        ExerciseInfo(exerciseName: "레그 레이즈", group: 1),
        ExerciseInfo(exerciseName: "러시안 트위스트", group: 1),
        ExerciseInfo(exerciseName: "버피", group: 1),
        ExerciseInfo(exerciseName: "줄넘기", group: 2),
        ExerciseInfo(exerciseName: "마운틴 클라이머", group: 1),
        ExerciseInfo(exerciseName: "싸이클", group: 3),
        ExerciseInfo(exerciseName: "러닝", group: 3),
        ExerciseInfo(exerciseName: "덤벨 사이드 밴드", group: 1),
        ExerciseInfo(exerciseName: "클린", group: 1),
        ExerciseInfo(exerciseName: "저크", group: 1),
        ExerciseInfo(exerciseName: "바벨 오버헤드 스쿼트", group: 1),
        ExerciseInfo(exerciseName: "덤벨 스내치", group: 1),
        ExerciseInfo(exerciseName: "덤벨 컬", group: 1),
        ExerciseInfo(exerciseName: "덤벨 리스트 컬", group: 1),
        ExerciseInfo(exerciseName: "덤벨 킥백", group: 1),
        ExerciseInfo(exerciseName: "케이블 푸시 다운", group: 1),
        ExerciseInfo(exerciseName: "이지바 컬", group: 1),
        ExerciseInfo(exerciseName: "케이블 컬", group: 1),
        ExerciseInfo(exerciseName: "시티드 덤벨 익스텐션", group: 1),
        ExerciseInfo(exerciseName: "바벨 리스트 컬", group: 1),
        ExerciseInfo(exerciseName: "암 컬 머신", group: 1),
        ExerciseInfo(exerciseName: "오버헤드 프레스", group: 1),
        ExerciseInfo(exerciseName: "덤벨 숄더 프레스", group: 1),
        ExerciseInfo(exerciseName: "아놀드 덤벨 프레스", group: 1),
        ExerciseInfo(exerciseName: "바벨 슈러그", group: 1),
        ExerciseInfo(exerciseName: "스미스머신 슈러그", group: 1),
        ExerciseInfo(exerciseName: "덤벨 벤치프레스", group: 1),
        ExerciseInfo(exerciseName: "바벨 백스쿼트", group: 1),
        ExerciseInfo(exerciseName: "덤벨 런지", group: 1),
        ExerciseInfo(exerciseName: "브이 업", group: 1),
        ExerciseInfo(exerciseName: "행잉 레그 레이즈", group: 1),
        ExerciseInfo(exerciseName: "푸시업", group: 1)
    ]
}

extension ExerciseInfo {
    
    // 운동 리스트 갯수
    static var numOfExerciseInfoList: Int {
        return ExerciseInfoList.count
    }
    
    // 정렬된 운동이름 리스트로 가져오기
    static func getExerciseInfoList() -> [String] {
        var exNames: [String] = []

        for i in sortedList {
            exNames.append(i.exerciseName)
        }
        return exNames
    }
    
    // 운동리스트 정렬하기
    static var sortedList: [ExerciseInfo] {
        let sortedlist = ExerciseInfoList.sorted { prev, next in
            return prev.exerciseName < next.exerciseName
        }
        return sortedlist
    }

    // 정렬된 리스트에서 인덱스를 통해 운동이름 가져오기
    static func exerciseinfo(index: Int) -> ExerciseInfo {
        return sortedList[index]
    }
}
