//
//  saveExerciseViewController2.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine

class saveExerciseViewController2: UIViewController {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var hourField: UITextField!
    @IBOutlet weak var minuteField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    
    var viewModel: saveExerciseViewModel!
    var subscriptions = Set<AnyCancellable>()
    
    // getTopViewController
    let keyWindow = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive })
        .map({ $0 as? UIWindowScene })
        .compactMap({ $0 })
        .first?.windows
        .filter({ $0.isKeyWindow }).first
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonConfigure()
        textFieldConfigure()
        bind()
    }
    
    func textFieldConfigure() {
        distanceField.delegate = self
        hourField.delegate = self
        minuteField.delegate = self
        distanceField.tag = 1
    }
    
    func bind() {
        viewModel.$DetailItem
//            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { detail in
                self.exerciseLabel.text = detail?.exerciseName
            }.store(in: &subscriptions)
    }
    
    func buttonConfigure() {
        saveBtn.layer.cornerRadius = 30
    }

    @IBAction func closeButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        if let vc = keyWindow?.visibleViewController {
            guard let field1 = distanceField.text, !field1.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "거리를 입력하세요.", View: vc)
            }
            let checkedDistanceNum = viewModel.stringToDouble(input: field1)
            if checkedDistanceNum == -1 {
                return viewModel.warningExerciseMessage(ment: "거리를 정확히 입력해 주세요.", View: vc)
            }
            if checkedDistanceNum <= 0 {
                return viewModel.warningExerciseMessage(ment: "거리는 0km 보다 적을 수 없습니다.", View: vc)
            }
            if checkedDistanceNum > 100 {
                return viewModel.warningExerciseMessage(ment: "거리는 100km 보다 많을 수 없습니다.", View: vc)
            }
            
            guard let field2 = hourField.text, !field2.isEmpty else {
                
                guard let field3 = minuteField.text, !field3.isEmpty else {
                    // 시간, 분 둘다 비어있을 때
                    return viewModel.warningExerciseMessage(ment: "시간과 분 중에 하나를 입력하세요", View: vc)
                }
                // 시간 비어있지만 분이 있는 경우
                let checkedMinuteNum = viewModel.stringToInt(input: field3)
                if checkedMinuteNum == -1 {
                    return viewModel.warningExerciseMessage(ment: "분을 정확히 입력해 주세요.", View: vc)
                }
                if checkedMinuteNum <= 0 {
                    return viewModel.warningExerciseMessage(ment: "올바른 시간(분)을 입력해 주세요.", View: vc)
                }
                if checkedMinuteNum >= 60 {
                    return viewModel.warningExerciseMessage(ment: "시간(분)은 60분 보다 많을 수 없습니다.", View: vc)
                }
                // 여기서 시간 없고 분만 있는 경우 -> 분으로 저장
                saveEx(distanceNum: checkedDistanceNum, timeNum: checkedMinuteNum)
                return viewModel.saveExerciseMessage(View: vc)
            }
            // 시간 있을 때 체크
            let checkedHourlNum = viewModel.stringToInt(input: field2)
            if checkedHourlNum == -1 {
                return viewModel.warningExerciseMessage(ment: "시간을 정확히 입력해 주세요.", View: vc)
//                return
            }
            if checkedHourlNum < 0 {
                return viewModel.warningExerciseMessage(ment: "올바른 시간을 입력해 주세요.", View: vc)
            }
            if checkedHourlNum >= 24 {
                return viewModel.warningExerciseMessage(ment: "시간은 24시간 보다 많을 수 없습니다.", View: vc)
            }
            
            // 시간 있을 때, 분 확인 / 둘다 비어있는 경우는 위에서 확인함
            guard let field3 = minuteField.text, !field3.isEmpty else {
                // 시간 0, 분 비어있을 때
                if checkedHourlNum == 0 {
                    return viewModel.warningExerciseMessage(ment: "올바른 시간을 입력해 주세요.", View: vc)
                }
                let resultTime = calcTime(hour: checkedHourlNum)
                saveEx(distanceNum: checkedDistanceNum, timeNum: resultTime)
                return viewModel.saveExerciseMessage(View: vc)
            }
            
            // 시간, 분 모두 있을 때
            let checkMinuteNum = viewModel.stringToInt(input: field3)
            if checkMinuteNum == -1 {
                return viewModel.warningExerciseMessage(ment: "분을 정확히 입력해 주세요.", View: vc)
            }
            // 시간, 분 둘다 0인 경우 먼저 확인
            if checkedHourlNum == 0 && checkMinuteNum == 0 {
                return viewModel.warningExerciseMessage(ment: "올바른 시간을 입력해 주세요.", View: vc)
            }
            // 시간, 분 둘다 있지만 분이 0인 경우 ex) 1시간 0분
            if checkMinuteNum == 0 {
                let resultTime = calcTime(hour: checkedHourlNum)
                saveEx(distanceNum: checkedDistanceNum, timeNum: resultTime)
                return viewModel.saveExerciseMessage(View: vc)
            }
            if checkMinuteNum < 0 {
                return viewModel.warningExerciseMessage(ment: "올바른 시간(분)을 입력해 주세요.", View: vc)
            }
            if checkMinuteNum >= 60 {
                return viewModel.warningExerciseMessage(ment: "시간(분)은 60분 보다 많을 수 없습니다.", View: vc)
            }
            // 모든 경우 통과
            let resultTime = calcTime(hour: checkedHourlNum, min: checkMinuteNum)
            saveEx(distanceNum: checkedDistanceNum, timeNum: resultTime)
            return viewModel.saveExerciseMessage(View: vc)
        }
    }
    
    func calcTime(hour: Int16? = nil, min: Int16? = nil) -> Int16 {
        let calc_hour = (hour ?? 0) * 60
        let calc_min = min ?? 0
        return calc_hour + calc_min
    }
    
    func saveEx(distanceNum: Double, timeNum: Int16) {
        let saveExerciseInfo = aerobicExerciseInfo(exercise: exerciseLabel.text ?? "운동 없음", date: ExerciseViewController.pickDate, time: timeNum, distance: distanceNum)
        print(timeNum)
        print("Info: \(saveExerciseInfo)")
        ConfigDataStore.saveCoreData(info: saveExerciseInfo)
    }
}

extension saveExerciseViewController2: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // backspace 허용
        if let char = string.cString(using: String.Encoding.utf8) {
            let isBackSpace = strcmp(char, "\\b")
            if isBackSpace == -92 {
                return true
            }
        }
        
        switch textField.tag {
        case 1:
            guard let text = textField.text else { return false }
            if text.count >= 4 {
                return false
            }
            return true
        
        default:
            guard let text = textField.text else { return false }
            if text.count >= 2 {
                return false
            }
            return true
        }
    }
}
