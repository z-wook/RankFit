//
//  aerobicExerciseInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation

struct aerobicExerciseInfo: Codable, Hashable {
    var id = UUID()
    let exercise: String
    let tableName: String
    let date: String
    let time: Int16
    let distance: Double
    let saveTime: String
    let done: Bool
}

extension aerobicExerciseInfo {
    init(exercise: String, table_Name: String ,date: String, time: Int16, distance: Double, saveTime: String? = nil, done: Bool? = nil) {
        self.exercise = exercise
        self.tableName = table_Name
        self.date = date
        self.time = time
        self.distance = distance
        self.saveTime = saveTime ?? ""
        self.done = done ?? false
    }
}
