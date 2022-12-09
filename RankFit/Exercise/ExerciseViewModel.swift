//
//  ExerciseViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation
import Combine

final class ExerciseViewModel {
    let storedExercises: CurrentValueSubject<[AnyHashable], Never> // 이걸 시간순으로 정렬
    
    init(data: [AnyHashable]? = nil) {
        self.storedExercises = CurrentValueSubject(data ?? [])
    }
}

extension ExerciseViewModel {
    func selectDate(date: String) {
        let exerciseData = ConfigDataStore.fetchCoreData(date: date)
        
        // 시간순 정렬
        let sortedData = exerciseData.sorted { prev, next in
            if let prevEx = prev as? aerobicExerciseInfo {
                if let nextEx = next as? aerobicExerciseInfo {
                    return prevEx.saveTime < nextEx.saveTime
                } else {
                    let nextEx = next as! anaerobicExerciseInfo
                    return prevEx.saveTime < nextEx.saveTime
                }
            } else {
                let prevEx = prev as! anaerobicExerciseInfo
                if let nextEx = next as? aerobicExerciseInfo {
                    return prevEx.saveTime < nextEx.saveTime
                } else {
                    let nextEx = next as! anaerobicExerciseInfo
                    return prevEx.saveTime < nextEx.saveTime
                }
            }
        }
        storedExercises.send(sortedData)
    }
}
