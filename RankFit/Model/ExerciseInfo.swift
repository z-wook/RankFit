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
    let category: String
}

extension ExerciseInfo {
    // group1 = Anaerobic
    // group2 = Anaerobic(세트, 개수만 필요한 운동 / 무게가 필요 없는 운동)
    // group3 = Aerobic
    // group4 = 플랭크(세트, 시간 필요한 운동)
    static let ExerciseInfoList: [ExerciseInfo] = [
        ExerciseInfo(exerciseName: "숄더 프레스", table_name: "shouldermuscles", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "랫 풀 다운", table_name: "latpulldown", group: 1, category: "등"),
        ExerciseInfo(exerciseName: "벤치 프레스", table_name: "benchpress", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "케이블 로우", table_name: "cablerow", group: 1, category: "등"),
        ExerciseInfo(exerciseName: "딥스", table_name: "dips", group: 2, category: "가슴"),
        ExerciseInfo(exerciseName: "디클라인 벤치 프레스", table_name: "DeclineBenchPress", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "트라이셉스 푸시 다운", table_name: "tricepspushdown", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "데드리프트", table_name: "deadlift", group: 1, category: "전신"),
        ExerciseInfo(exerciseName: "슈러그", table_name: "shrug", group: 1, category: "상체"),
        ExerciseInfo(exerciseName: "스쿼트", table_name: "squat", group: 2, category: "하체"),
        ExerciseInfo(exerciseName: "레그 프레스", table_name: "legpress", group: 1, category: "하체"),
        ExerciseInfo(exerciseName: "레그 익스텐션", table_name: "legtension", group: 1, category: "하체"),
        ExerciseInfo(exerciseName: "런지", table_name: "fingering", group: 2, category: "하체"),
        ExerciseInfo(exerciseName: "백 익스텐션", table_name: "backnailtension", group: 2, category: "등"),
        ExerciseInfo(exerciseName: "윗몸 일으키기", table_name: "situpcorrector", group: 2, category: "복부"),
        ExerciseInfo(exerciseName: "아놀드 프레스", table_name: "ArnoldPress", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "사이드 레터럴 레이즈", table_name: "Sidelateralraise", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "바벨 로우", table_name: "barbellrow", group: 1, category: "등"),
        ExerciseInfo(exerciseName: "풀업", table_name: "pullup", group: 2, category: "등"),
        ExerciseInfo(exerciseName: "덤벨 로우", table_name: "dumbbellrow", group: 1, category: "상체"),
        ExerciseInfo(exerciseName: "플랭크", table_name: "plank", group: 4, category: "복부"),
        ExerciseInfo(exerciseName: "크런치", table_name: "crunch", group: 2, category: "복부"),
        ExerciseInfo(exerciseName: "레그 레이즈", table_name: "legrise", group: 2, category: "복부"),
        ExerciseInfo(exerciseName: "러시안 트위스트", table_name: "Russiantwist", group: 2, category: "복부"),
        ExerciseInfo(exerciseName: "버피", table_name: "buffy", group: 2, category: "전신"),
        ExerciseInfo(exerciseName: "줄넘기", table_name: "JumpRope", group: 2, category: "전신"),
        ExerciseInfo(exerciseName: "마운틴 클라이머", table_name: "posterclimber", group: 2, category: "전신"),
        ExerciseInfo(exerciseName: "싸이클", table_name: "cycle", group: 3, category: "유산소"),
        ExerciseInfo(exerciseName: "러닝", table_name: "running", group: 3, category: "유산소"),
        ExerciseInfo(exerciseName: "덤벨 사이드 밴드", table_name: "dumbbellsideband", group: 1, category: "복부"),
        ExerciseInfo(exerciseName: "클린", table_name: "clean", group: 1, category: "전신"),
        ExerciseInfo(exerciseName: "저크", table_name: "jerk", group: 1, category: "전신"),
        ExerciseInfo(exerciseName: "바벨 오버헤드 스쿼트", table_name: "BarbellAdmissionHeadSquat", group: 1, category: "하체"),
        ExerciseInfo(exerciseName: "덤벨 스내치", table_name: "dumbbellsnatch", group: 1, category: "전신"),
        ExerciseInfo(exerciseName: "덤벨 컬", table_name: "dumbbellcurl", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "덤벨 리스트 컬", table_name: "DumbbellistCurl", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "덤벨 킥백", table_name: "dumbbellkickback", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "케이블 푸시 다운", table_name: "cablepushdown", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "이지바 컬", table_name: "EasyBarCurl", group: 2, category: "팔"),
        ExerciseInfo(exerciseName: "케이블 컬", table_name: "kcurl", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "시티드 덤벨 익스텐션", table_name: "TedDumbbellSneakers", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "바벨 리스트 컬", table_name: "barbellistcurls", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "암 컬 머신", table_name: "armcurlmachine", group: 1, category: "팔"),
        ExerciseInfo(exerciseName: "오버헤드 프레스", table_name: "stainedpress", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "덤벨 숄더 프레스", table_name: "dumbbellspine", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "아놀드 덤벨 프레스", table_name: "ArnoldDumbbellPress", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "바벨 슈러그", table_name: "barbellshrug", group: 1, category: "어깨"),
        ExerciseInfo(exerciseName: "스미스머신 슈러그", table_name: "machineshrug", group: 1, category: "등"),
        ExerciseInfo(exerciseName: "덤벨 벤치프레스", table_name: "dumbbellbenchpress", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "바벨 백스쿼트", table_name: "barbellbacksquat", group: 1, category: "하체"),
        ExerciseInfo(exerciseName: "덤벨 런지", table_name: "dumbbelllunge", group: 1, category: "하체"),
        ExerciseInfo(exerciseName: "브이 업", table_name: "Bryup", group: 2, category: "복부"),
        ExerciseInfo(exerciseName: "행잉 레그 레이즈", table_name: "hanginglegrise", group: 2, category: "복부"),
        ExerciseInfo(exerciseName: "푸시업", table_name: "pushup", group: 2, category: "가슴"),
        ExerciseInfo(exerciseName: "버터플라이", table_name: "Butterfly", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "체스트 프레스", table_name: "ChestPress", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "시티드 체스트 프레스", table_name: "SeatedChestPress", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "로타리 토르소", table_name: "RotaryTorso", group: 1, category: "복부"),
        ExerciseInfo(exerciseName: "인클라인 벤치 프레스", table_name: "Inclinebenchpress", group: 1, category: "가슴"),
        ExerciseInfo(exerciseName: "인클라인 덤벨 프레스", table_name: "Inclinedumbbellpress", group: 1, category: "가슴")
    ]
}

extension ExerciseInfo {
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
