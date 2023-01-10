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
    let saveTime: String
    var done: Bool
}

extension anaerobicExerciseInfo {
    init(exercise: String, table_Name: String, date: String, set: Int16, weight: Float, count: Int16, saveTime: String? = nil, done: Bool? = nil) {
        self.exercise = exercise
        self.tableName = table_Name
        self.date = date
        self.set = set
        self.weight = weight
        self.count = count
        self.saveTime = saveTime ?? ""
        self.done = done ?? false
    }
}
