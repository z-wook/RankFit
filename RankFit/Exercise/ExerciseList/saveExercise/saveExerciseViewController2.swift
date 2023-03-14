//
//  saveExerciseViewController2.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import FirebaseAuth
import Combine

class saveExerciseViewController2: UIViewController {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var hourField: UITextField!
    @IBOutlet weak var minuteField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var viewModel: saveExerciseViewModel!
    var exInfo: aerobicExerciseInfo!
    let serverState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var tableName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    private func configure() {
        exerciseLabel.tintColor = UIColor(named: "link_cyan")
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        saveBtn.layer.cornerRadius = 20
        distanceField.delegate = self
        hourField.delegate = self
        minuteField.delegate = self
        distanceField.tag = 1
        distanceField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        hourField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        minuteField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
    }
    
    func bind() {
        viewModel.$DetailItem
            .receive(on: RunLoop.main)
            .sink { info in
                self.exerciseLabel.text = info?.exerciseName
                self.tableName = info?.table_name
            }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result == true {
                print("서버 운동 저장 성공")
                if let vc = self.view.window?.visibleViewController() {
                    let save = ExerciseCoreData.saveCoreData(info: self.exInfo)
                    if save == true {
                        print("CoreData 저장 완료")
                        configFirebase.saveEx(exName: self.exInfo.exercise, time: self.exInfo.saveTime, uuid: self.exInfo.id.uuidString, date: self.exInfo.date)
                        self.viewModel.saveSuccessExMessage(View: vc)
                    } else {
                        print("CoreData 저장 실패")
                        configServer.sendDeleteEx(info: self.exInfo)
                        self.viewModel.saveFailExMessage(View: vc)
                    }
                } else {
                    print("keyWindow error")
                    configServer.sendDeleteEx(info: self.exInfo)
                    configFirebase.errorReport(type: "saveExerciseVC1.bind", descriptions: "keyWindow error")
                    self.showAlert()
                }
            } else {
                print("서버 운동 저장 실패")
                self.showAlert()
            }
        }.store(in: &subscriptions)
    }

    @IBAction func closeButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert()
            return
        }
        if let vc = self.view.window?.visibleViewController() {
            guard let field1 = distanceField.text, !field1.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "거리를 입력해 주세요.", View: vc)
            }
            let checkedDistanceNum = viewModel.stringToDouble(input: field1)
            if checkedDistanceNum == -1 {
                return viewModel.warningExerciseMessage(ment: "거리를 정확히 입력해 주세요.", View: vc)
            } else if checkedDistanceNum <= 0 {
                return viewModel.warningExerciseMessage(ment: "거리는 0km보다 적을 수 없습니다.", View: vc)
            } else if checkedDistanceNum > 100 {
                return viewModel.warningExerciseMessage(ment: "거리는 100km보다 많을 수 없습니다.", View: vc)
            }
            
            guard let field2 = hourField.text, !field2.isEmpty else {
                guard let field3 = minuteField.text, !field3.isEmpty else {
                    // 시간, 분 둘다 비어있을 때
                    return viewModel.warningExerciseMessage(ment: "시간과 분 중에 하나를 입력해 주세요.", View: vc)
                }
                // 시간 비어있지만 분이 있는 경우
                let checkedMinuteNum = viewModel.stringToInt(input: field3)
                if checkedMinuteNum == -1 {
                    return viewModel.warningExerciseMessage(ment: "(분)을 정확히 입력해 주세요.", View: vc)
                } else if checkedMinuteNum <= 0 {
                    return viewModel.warningExerciseMessage(ment: "올바른 시간(분)을 입력해 주세요.", View: vc)
                } else if checkedMinuteNum >= 60 {
                    return viewModel.warningExerciseMessage(ment: "시간(분)은 60분보다 많을 수 없습니다.", View: vc)
                }
                // 여기서 시간 없고 분만 있는 경우 -> 분으로 저장
                saveEx(distanceNum: checkedDistanceNum, timeNum: checkedMinuteNum)
                return
            }
            // 시간 있을 때 체크
            let checkedHourlNum = viewModel.stringToInt(input: field2)
            if checkedHourlNum == -1 {
                return viewModel.warningExerciseMessage(ment: "시간을 정확히 입력해 주세요.", View: vc)
            } else if checkedHourlNum < 0 {
                return viewModel.warningExerciseMessage(ment: "올바른 시간을 입력해 주세요.", View: vc)
            } else if checkedHourlNum >= 24 {
                return viewModel.warningExerciseMessage(ment: "시간은 24시간보다 많을 수 없습니다.", View: vc)
            }
            
            // 시간 있을 때, 분 확인 / 둘다 비어있는 경우는 위에서 확인함
            guard let field3 = minuteField.text, !field3.isEmpty else {
                // 시간 0, 분 비어있을 때
                if checkedHourlNum == 0 {
                    return viewModel.warningExerciseMessage(ment: "올바른 시간을 입력해 주세요.", View: vc)
                }
                let resultTime = calcTime(hour: checkedHourlNum)
                saveEx(distanceNum: checkedDistanceNum, timeNum: resultTime)
                return
            }
            
            // 시간, 분 모두 있을 때
            let checkMinuteNum = viewModel.stringToInt(input: field3)
            if checkMinuteNum == -1 {
                return viewModel.warningExerciseMessage(ment: "(분)을 정확히 입력해 주세요.", View: vc)
            } else if checkedHourlNum == 0 && checkMinuteNum == 0 { // 시간, 분 둘다 0인 경우 먼저 확인
                return viewModel.warningExerciseMessage(ment: "올바른 시간을 입력해 주세요.", View: vc)
            } else if checkMinuteNum == 0 { // 시간, 분 둘다 있지만 분이 0인 경우 ex) 1시간 0분
                let resultTime = calcTime(hour: checkedHourlNum)
                saveEx(distanceNum: checkedDistanceNum, timeNum: resultTime)
                return viewModel.saveSuccessExMessage(View: vc)
            } else if checkMinuteNum < 0 {
                return viewModel.warningExerciseMessage(ment: "올바른 시간(분)을 입력해 주세요.", View: vc)
            } else if checkMinuteNum >= 60 {
                return viewModel.warningExerciseMessage(ment: "시간(분)은 60분보다 많을 수 없습니다.", View: vc)
            }
            let resultTime = calcTime(hour: checkedHourlNum, min: checkMinuteNum)
            saveEx(distanceNum: checkedDistanceNum, timeNum: resultTime)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension saveExerciseViewController2 {
    private func showAlert() {
        let alert = UIAlertController(title:"운동 저장 실패", message: "잠시 후 다시 시도해 주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default, handler: { _ in
            self.dismiss(animated: true)
        })
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func loginAlert() {
        let alert = UIAlertController(title: "로그아웃 상태", message: "현재 로그아웃 되어있어 운동을 저장할 수 없습니다.\n로그인을 먼저 해주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func calcTime(hour: Int16? = nil, min: Int16? = nil) -> Int16 {
        let calc_hour = (hour ?? 0) * 60
        let calc_min = min ?? 0
        return calc_hour + calc_min
    }
    
    private func saveEx(distanceNum: Double, timeNum: Int16) {
        saveBtn.isEnabled = false
        // prevent modalView dismiss
        self.isModalInPresentation = true
        backgroundView.isHidden = false
        indicator.startAnimating()
        exInfo = aerobicExerciseInfo(exercise: exerciseLabel.text ?? "운동 없음", table_Name: tableName, date: ExerciseViewController.pickDate, time: timeNum, distance: distanceNum, saveTime: Int64(TimeStamp.getCurrentTimestamp()))
        configServer.sendSaveEx(info: exInfo, subject: serverState)
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
