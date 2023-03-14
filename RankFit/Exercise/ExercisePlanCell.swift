//
//  ExercisePlanCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import FirebaseAuth
import Combine

class ExercisePlanCell: UICollectionViewCell {
    
    @IBOutlet weak var exerciseNameLabel: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label1_num: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label2_num: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label3_num: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var Label1_Leading: NSLayoutConstraint!
    @IBOutlet weak var Label2_Leading: NSLayoutConstraint! // 25
    @IBOutlet weak var Label2_Trailing: NSLayoutConstraint! // 28
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 10
    }
}

extension ExercisePlanCell {
    func configure(item: AnyHashable, vm: ExerciseViewModel) {
        guard let aerobicInfo = item as? aerobicExerciseInfo else {
            let anaerobicInfo = item as! anaerobicExerciseInfo
            return AnaerobicCellUpdate(info: anaerobicInfo)
        }
        AerobicCellUpdate(info: aerobicInfo)
    }
    
    private func AerobicCellUpdate(info: aerobicExerciseInfo) {
        exerciseNameLabel.text = info.exercise
        label1.text = "거리(km)"
        label1_num.text = "\(info.distance)"
        label2.text = "시간(분)"
        label2_num.text = "\(info.time)"
        label3.text = ""
        label3_num.text = ""
        deleteBtn.isEnabled = true // 삭제 후 재사용 셀의 버튼을 초기화 시켜주기 위함
        
        Label2_Leading.constant = 35
        Label2_Trailing.constant = 35
        
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
    
    private func AnaerobicCellUpdate(info: anaerobicExerciseInfo) {
        exerciseNameLabel.text = info.exercise
        label1.text = "세트"
        label1_num.text = "\(info.set)"
        label2.text = "개수"
        label2_num.text = "\(info.count)"
        label3.text = "무게(kg)"
        label3_num.text = "\(info.weight)"
        deleteBtn.isEnabled = true // 삭제 후 재사용 셀의 버튼을 초기화 시켜주기 위함
        
        Label2_Leading.constant = 40
        Label2_Trailing.constant = 40
        
        if info.weight == 0 {
            label3.isHidden = true
            label3_num.isHidden = true
        } else {
            label3.isHidden = false
            label3_num.isHidden = false
        }
        
        if info.exercise == "플랭크" {
            let timeStr = String(format: "%.0f", info.exTime)
            label2.text = "시간(초)"
            label2_num.text = timeStr
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
