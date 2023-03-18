//
//  ExerciseListViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation
import UIKit
import Combine

final class ExerciseListViewModel {
    
    let items: CurrentValueSubject<[ExerciseInfo], Never> // 현재 보여지는 items
    let selectedItem: CurrentValueSubject<ExerciseInfo?, Never> // 클릭 순간 item
    
    init(items: [ExerciseInfo], selectedItem: ExerciseInfo? = nil) {
        self.items = CurrentValueSubject(items)
        self.selectedItem = CurrentValueSubject(selectedItem)
    }
}

extension ExerciseListViewModel {
    func didSelect(at indexPath: IndexPath) {
        let selectItem = items.value[indexPath.item]
        selectedItem.send(selectItem)
    }
    
    func filteredExercises(filter: String? = nil) {
        if let filter = filter {
            let filtered = ExerciseInfo.sortedList.filter { $0.exerciseName.contains(filter) }
            items.send(filtered)
        }
        
        if filter == "" {
            items.send(ExerciseInfo.sortedList)
        }
    }
    
    func get_category(categoryName: String) {
        if categoryName == "전체" {
            items.send(ExerciseInfo.sortedList)
        } else {
            let filteredList = ExerciseInfo.sortedList.filter { info in
                return info.category == categoryName
            }
            items.send(filteredList)
        }
    }
}
