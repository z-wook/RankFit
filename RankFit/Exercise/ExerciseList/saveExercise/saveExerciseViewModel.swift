//
//  saveExerciseViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation
import UIKit
import Combine

final class saveExerciseViewModel {
    
    @Published var DetailItem: ExerciseInfo? = nil
    
    init(DetailItem: ExerciseInfo? = nil) {
        self.DetailItem = DetailItem
    }
}

extension saveExerciseViewModel {
    func stringToInt(input: String) -> Int16 {
        guard let result = Int16(input) else { return -1 }
        if result == 0 {
            return 0
        }
        
        if result < 0 {
            return -2
        }
        
        return result
    }
    
    func stringToFloat(input: String) -> Float {
        guard let result = Float(input) else { return -1 }
        if result <= 0 {
            return 0
        }
        return result
    }
    
    func stringToDouble(input: String) -> Double {
        guard let result = Double(input) else { return -1 }
        if result <= 0 {
            return 0
        }
        return result
    }
    
    func warningExerciseMessage(ment text: String, View vc: UIViewController) {
        let alert = UIAlertController(title: "잘못된 입력", message: "\(text)", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .destructive, handler: nil)
        alert.addAction(ok)
        vc.present(alert, animated: true, completion: nil)
    }

    func saveSuccessExMessage(View vc: UIViewController) {
        let alert = UIAlertController(title:"저장 완료", message: "운동이 저장되었습니다.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default, handler: { _ in
            vc.dismiss(animated: true)
        })
        alert.addAction(ok)
        vc.present(alert, animated: true, completion: nil)
    }
    
    func saveFailExMessage(View vc: UIViewController) {
        let alert = UIAlertController(title:"저장 실패", message: "잠시 후 다시 시도해 주세요.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default, handler: { _ in
            vc.dismiss(animated: true)
        })
        alert.addAction(ok)
        vc.present(alert, animated: true, completion: nil)
    }
}
