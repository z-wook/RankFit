//
//  anaerobicExerciseInfo.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation

struct anaerobicExerciseInfo: Codable, Hashable {
    var id = UUID()
    let exercise: String
    let tableName: String
    let date: String
    let set: Int16
    let weight: Float
    let count: Int16
    var exTime: Double
    let saveTime: Int64
    var done: Bool
}

extension anaerobicExerciseInfo {
    init(exercise: String, table_Name: String, date: String, set: Int16, weight: Float, count: Int16, exTime: Double? = nil, saveTime: Int64? = nil, done: Bool? = nil) {
        self.exercise = exercise
        self.tableName = table_Name
        self.date = date
        self.set = set
        self.weight = weight
        self.count = count
        self.exTime = exTime ?? 0
        self.saveTime = saveTime ?? 0
        self.done = done ?? false
    }
}
