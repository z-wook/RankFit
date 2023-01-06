//
//  ExercisePlanCell.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
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
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var Label1_Leading: NSLayoutConstraint!
    @IBOutlet weak var Label2_Leading: NSLayoutConstraint! // 25
    @IBOutlet weak var Label2_Trailing: NSLayoutConstraint! // 28
    
    var sendState: PassthroughSubject<Bool, Never>!
    var subscriptions = Set<AnyCancellable>()
    var viewModel: ExerciseViewModel!
    var exerciseInfo: AnyHashable!
    var exerciseUUID: UUID!
    var exerciseEntityName: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        contentView.backgroundColor = UIColor.separator
        contentView.layer.cornerRadius = 10
    }
    
    
    @IBAction func removeBtn(_ sender: UIButton) {
        guard let aerobicInfo = exerciseInfo as? aerobicExerciseInfo else {
            let anaerobicInfo = exerciseInfo as! anaerobicExerciseInfo
            SendAnaerobicEx.sendDeleteEx(info: anaerobicInfo, subject: sendState)
            return
        }
        SendAerobicEx.sendDeleteEx(info: aerobicInfo, subject: sendState)
    }
    
    func bind() {
        sendState.receive(on: RunLoop.main)
            .sink { result in
                if result == true {
                    let deleteState = ConfigDataStore.deleteCoreData(id: self.exerciseUUID, entityName: self.exerciseEntityName) // return T/F
                    if deleteState {
                        self.viewModel.selectDate(date: ExerciseViewController.pickDate)
                    } else {
                        print("App Delete Error")
                    }
                } else {
                    print("서버에 삭제 요청 에러")
                }
            }.store(in: &subscriptions)
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
            sendState = PassthroughSubject()
            bind()
            return AnaerobicCellUpdate(info: anaerobicInfo)
        }
        self.exerciseUUID = aerobicInfo.id
        self.exerciseEntityName = "Aerobic"
        self.viewModel = vm
        sendState = PassthroughSubject()
        bind()
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
    
    func AnaerobicCellUpdate(info: anaerobicExerciseInfo) {
        exerciseNameLabel.text = info.exercise
        label1.text = "세트"
        label1_num.text = "\(info.set)"
        label2.text = "개수"
        label2_num.text = "\(info.count)"
        label3.text = "무게(kg)"
        label3_num.text = "\(info.weight)"
        
        Label2_Leading.constant = 40
        Label2_Trailing.constant = 40
        
        if info.weight == 0 {
            label3.isHidden = true
            label3_num.isHidden = true
        } else {
            label3.isHidden = false
            label3_num.isHidden = false
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
