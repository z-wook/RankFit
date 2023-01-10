//
//  ExerciseInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation

struct ExerciseInfo: Codable, Hashable {
    let exerciseName: String
    let table_name: String
    let group: Int
}

extension ExerciseInfo {
    // group1 = Anaerobic
    // group2 = Anaerobic(세트, 개수만 필요한 운동 / 무게가 필요 없는 운동)
    // group3 = Aerobic
    static let ExerciseInfoList: [ExerciseInfo] = [
        ExerciseInfo(exerciseName: "숄더 프레스", table_name: "shoulder muscles", group: 1),
        ExerciseInfo(exerciseName: "랫 풀 다운", table_name: "lat pull down", group: 1),
        ExerciseInfo(exerciseName: "벤치 프레스", table_name: "bench press", group: 1),
        ExerciseInfo(exerciseName: "케이블 로우", table_name: "cable row", group: 1),
        ExerciseInfo(exerciseName: "딥스", table_name: "dips", group: 1),
        ExerciseInfo(exerciseName: "디클라인 벤치 프레스", table_name: "Decline Bench Press", group: 1),
        ExerciseInfo(exerciseName: "트라이셉스 푸시 다운", table_name: "triceps pushdown", group: 1),
        ExerciseInfo(exerciseName: "데드리프트", table_name: "deadlift", group: 1),
        ExerciseInfo(exerciseName: "슈러그", table_name: "shrug", group: 1),
        ExerciseInfo(exerciseName: "스쿼트", table_name: "squat", group: 2),
        ExerciseInfo(exerciseName: "레그 프레스", table_name: "leg press", group: 1),
        ExerciseInfo(exerciseName: "레그 익스텐션", table_name: "leg tension", group: 1),
        ExerciseInfo(exerciseName: "런지", table_name: "fingering", group: 2),
        ExerciseInfo(exerciseName: "백 익스텐션", table_name: "back nail tension", group: 1),
        ExerciseInfo(exerciseName: "윗몸 일으키기", table_name: "sit up corrector", group: 2),
        ExerciseInfo(exerciseName: "아놀드 프레스", table_name: "Arnold Press", group: 1),
        ExerciseInfo(exerciseName: "바벨 로우", table_name: "barbell row", group: 1),
        ExerciseInfo(exerciseName: "풀업", table_name: "pull up", group: 1),
        ExerciseInfo(exerciseName: "덤벨 로우", table_name: "dumbbell row", group: 1),
        ExerciseInfo(exerciseName: "플랭크", table_name: "plank", group: 2),
        ExerciseInfo(exerciseName: "크런치", table_name: "crunch", group: 1),
        ExerciseInfo(exerciseName: "레그 레이즈", table_name: "leg rise", group: 1),
        ExerciseInfo(exerciseName: "러시안 트위스트", table_name: "Russian twist", group: 1),
        ExerciseInfo(exerciseName: "버피", table_name: "buffy", group: 1),
        ExerciseInfo(exerciseName: "줄넘기", table_name: "Jump Rope", group: 2),
        ExerciseInfo(exerciseName: "마운틴 클라이머", table_name: "poster climber", group: 1),
        ExerciseInfo(exerciseName: "싸이클", table_name: "cycle", group: 3),
        ExerciseInfo(exerciseName: "러닝", table_name: "running", group: 3),
        ExerciseInfo(exerciseName: "덤벨 사이드 밴드", table_name: "dumbbell side band", group: 1),
        ExerciseInfo(exerciseName: "클린", table_name: "clean", group: 1),
        ExerciseInfo(exerciseName: "저크", table_name: "jerk", group: 1),
        ExerciseInfo(exerciseName: "바벨 오버헤드 스쿼트", table_name: "Barbell Admission Head Squat", group: 1),
        ExerciseInfo(exerciseName: "덤벨 스내치", table_name: "dumbbell snatch", group: 1),
        ExerciseInfo(exerciseName: "덤벨 컬", table_name: "dumbbell curl", group: 1),
        ExerciseInfo(exerciseName: "덤벨 리스트 컬", table_name: "Dumbbellist Curl", group: 1),
        ExerciseInfo(exerciseName: "덤벨 킥백", table_name: "dumbbell kickback", group: 1),
        ExerciseInfo(exerciseName: "케이블 푸시 다운", table_name: "cable push down", group: 1),
        ExerciseInfo(exerciseName: "이지바 컬", table_name: "Easy Bar Curl", group: 1),
        ExerciseInfo(exerciseName: "케이블 컬", table_name: "k curl", group: 1),
        ExerciseInfo(exerciseName: "시티드 덤벨 익스텐션", table_name: "Ted Dumbbell Sneakers", group: 1),
        ExerciseInfo(exerciseName: "바벨 리스트 컬", table_name: "barbellist curls", group: 1),
        ExerciseInfo(exerciseName: "암 컬 머신", table_name: "arm curl machine", group: 1),
        ExerciseInfo(exerciseName: "오버헤드 프레스", table_name: "stained press", group: 1),
        ExerciseInfo(exerciseName: "덤벨 숄더 프레스", table_name: "dumbbell spine", group: 1),
        ExerciseInfo(exerciseName: "아놀드 덤벨 프레스", table_name: "Arnold Dumbbell Press", group: 1),
        ExerciseInfo(exerciseName: "바벨 슈러그", table_name: "barbell shrug", group: 1),
        ExerciseInfo(exerciseName: "스미스머신 슈러그", table_name: "machine shrug", group: 1),
        ExerciseInfo(exerciseName: "덤벨 벤치프레스", table_name: "dumbbell bench press", group: 1),
        ExerciseInfo(exerciseName: "바벨 백스쿼트", table_name: "barbell back squat", group: 1),
        ExerciseInfo(exerciseName: "덤벨 런지", table_name: "dumbbell lunge", group: 1),
        ExerciseInfo(exerciseName: "브이 업", table_name: "Bryup", group: 1),
        ExerciseInfo(exerciseName: "행잉 레그 레이즈", table_name: "hanging leg rise", group: 1),
        ExerciseInfo(exerciseName: "푸시업", table_name: "push up", group: 1)
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
