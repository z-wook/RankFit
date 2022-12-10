//
//  ExercisePlanCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit

class ExercisePlanCell: UICollectionViewCell {
    
    @IBOutlet weak var exerciseNameLabel: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label1_num: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label2_num: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label3_num: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    
    var viewModel: ExerciseViewModel!
    var exerciseInfo: AnyHashable!
    var exerciseUUID: UUID!
    var exerciseEntityName: String!
    
    @IBAction func removeBtn(_ sender: UIButton) {
        let deleteState = ConfigDataStore.deleteCoreData(id: exerciseUUID, entityName: exerciseEntityName) // return T/F
        
        if deleteState {
            viewModel.selectDate(date: ExerciseViewController.pickDate)
        } else {
            print("Delete Error")
        }
    }
}

extension ExercisePlanCell {
    
    func configure(item: AnyHashable, vm: ExerciseViewModel) {
        exerciseInfo = item
        guard let aerobicInfo = item as? aerobicExerciseInfo else {
            let anaerobicInfo = item as! anaerobicExerciseInfo
            self.exerciseUUID = anaerobicInfo.id
            self.exerciseEntityName = "Anaerobic"
            self.viewModel = vm
            return AnaerobicCellUpdate(info: anaerobicInfo)
        }
        self.exerciseUUID = aerobicInfo.id
        self.exerciseEntityName = "Aerobic"
        self.viewModel = vm
        AerobicCellUpdate(info: aerobicInfo)
    }
    
    func AerobicCellUpdate(info: aerobicExerciseInfo) {
        exerciseNameLabel.text = info.exercise
        label1.text = "거리(km)"
        label1_num.text = "\(info.distance)"
        label2.text = "시간(분)"
        label2_num.text = "\(info.time)"
        label3.text = ""
        label3_num.text = ""
        
        if info.done {
            stateLabel.text = "완료"
            stateLabel.textColor = .systemPink
            startBtn.isHidden = true
        } else {
            stateLabel.text = "미완료"
            stateLabel.textColor = .lightGray
            
            if ExerciseViewController.today == info.date {
                startBtn.isHidden = false
            } else {
                startBtn.isHidden = true
            }
        }
    }
    
    func AnaerobicCellUpdate(info: anaerobicExerciseInfo) {
        exerciseNameLabel.text = info.exercise
        label1.text = "세트"
        label1_num.text = "\(info.set)"
        label2.text = "개수"
        label2_num.text = "\(info.count)"
        label3.text = "무게(kg)"
        label3_num.text = "\(info.weight)"
        if info.weight == 0 {
            label3.isHidden = true
            label3_num.isHidden = true
        }
        if info.done {
            stateLabel.text = "완료"
            stateLabel.textColor = .systemPink
            startBtn.isHidden = true
        } else {
            stateLabel.text = "미완료"
            stateLabel.textColor = .lightGray
         
            if ExerciseViewController.today == info.date {
                startBtn.isHidden = false
            } else {
                startBtn.isHidden = true
            }
        }
    }
}
