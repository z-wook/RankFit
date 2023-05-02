//
//  saveExerciseViewController1.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import FirebaseAuth
import Combine

class saveExerciseViewController1: UIViewController {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setField: UITextField!
    @IBOutlet weak var countField: UITextField!
    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var exerciseType: UISegmentedControl!
    
    var viewModel: saveExerciseViewModel!
    var exInfo: anaerobicExerciseInfo!
    var hideCheck: Bool = true // 무게가 필요있는 운동이면 true
    let serverState = PassthroughSubject<Bool, Never>()
    let sendState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var tableName: String!
    var category: String!
    var type: String = "계획"
    var keyboardNoti1: Void?
    var keyboardNoti2: Void?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        subscriptions.removeAll()
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func exType(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.type = "계획"
        } else {
            self.type = "완료"
        }
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert()
            return
        }
        self.view.endEditing(true)
        saveExercise()
    }
    
    private func saveExercise() {
        if let vc = self.view.window?.visibleViewController() {
            guard let field1 = setField.text, !field1.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "세트를 입력해 주세요.", View: vc)
            }
            let checkedSetNum = viewModel.stringToInt(input: field1)
            if checkedSetNum == -1 {
                return viewModel.warningExerciseMessage(ment: "세트를 정확히 입력해 주세요.", View: vc)
            } else if checkedSetNum == 0 {
                return viewModel.warningExerciseMessage(ment: "세트는 0개가 될 수 없습니다.", View: vc)
            } else if checkedSetNum < 0 {
                return viewModel.warningExerciseMessage(ment: "세트는 0개보다 적을 수 없습니다.", View: vc)
            } else if checkedSetNum > 100 {
                return viewModel.warningExerciseMessage(ment: "100 세트 이하로 입력해 주세요.", View: vc)
            }

            guard let field2 = countField.text, !field2.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "개수를 입력하세요.", View: vc)
            }
            let checkCountNum = viewModel.stringToInt(input: field2)
            if checkCountNum == -1 {
                return viewModel.warningExerciseMessage(ment: "개수를 정확히 입력해 주세요.", View: vc)
            } else if checkCountNum == 0 {
                return viewModel.warningExerciseMessage(ment: "개수는 0개가 될 수 없습니다.", View: vc)
            } else if checkCountNum < 0 {
                return viewModel.warningExerciseMessage(ment: "개수는 0개보다 적을 수 없습니다.", View: vc)
            }
            
            var weightNum: Float = 0.0 // 무게 필요 없으면 0.0으로 저장
            // 무게가 필요 있는 운동의 경우
            if hideCheck {
                guard let field3 = weightField.text, !field3.isEmpty else {
                    return viewModel.warningExerciseMessage(ment: "무게를 입력해 주세요.", View: vc)
                }
                let checkedWeightNum = viewModel.stringToFloat(input: field3)
                if checkedWeightNum == -1 {
                    return viewModel.warningExerciseMessage(ment: "무게를 정확히 입력해 주세요.", View: vc)
                } else if checkedWeightNum <= 0 {
                    viewModel.warningExerciseMessage(ment: "무게는 0kg보다 적을 수 없습니다.", View: vc)
                    return
                } else if checkedWeightNum > 500 {
                    return viewModel.warningExerciseMessage(ment: "무게는 500kg를 넘을 수 없습니다.", View: vc)
                } else if checkedWeightNum < 1 {
                    return viewModel.warningExerciseMessage(ment: "무게는 1kg보다 적을 수 없습니다.", View: vc)
                }
                print("weight: \(checkedWeightNum)")
                weightNum = checkedWeightNum
            }
            saveBtn.isEnabled = false
            // prevent modalView dismiss
            self.isModalInPresentation = true
            backgroundView.isHidden = false
            indicator.startAnimating()
            
            // 무게가 필요없는 운동은 무게를 0으로 저장
            saveEx(setNum: checkedSetNum, weightNum: weightNum, countNum: checkCountNum)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension saveExerciseViewController1 {
    private func configure() {
        exerciseLabel.tintColor = UIColor(named: "link_cyan")
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        saveBtn.layer.cornerRadius = 20
        setField.delegate = self
        weightField.delegate = self
        countField.delegate = self
        setField.tag = 0
        countField.tag = 1
        weightField.tag = 2
        exerciseType.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        exerciseType.selectedSegmentTintColor = .systemOrange.withAlphaComponent(0.8)
        setField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        countField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        weightField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        if ExerciseViewController.today != ExerciseViewController.pickDate {
            // 오늘 날짜가 아닌 경우 계획으로만 저장시키기
            exerciseType.layer.isHidden = true
        }
        let screenHeight = UIScreen.main.bounds.size.height
        if screenHeight <= 667 {
            // Notification 등록
            setKeyboardObserver()
        }
    }
    override func keyboardWillShow(notification: NSNotification) {
        if self.view.window?.frame.origin.y == 0 {
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                if countField.isEditing || weightField.isEditing {
                    // 뷰를 키보드 높이만큼 올림
                    UIView.animate(withDuration: 0.7) {
                        self.view.window?.frame.origin.y -= keyboardHeight
                    }
                }
            }
        }
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        if self.view.window?.frame.origin.y != 0 {
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                UIView.animate(withDuration: 0.7) {
                    self.view.window?.frame.origin.y += keyboardHeight
                }
            }
        }
    }
    
    private func bind() {
        viewModel.$DetailItem
            .receive(on: RunLoop.main)
            .sink { info in
                self.exerciseLabel.text = info?.exerciseName
                self.tableName = info?.table_name
                self.category = info?.category
                if info?.group == 2 {
                    self.weightField.isHidden = true
                    self.weightLabel.isHidden = true
                    self.hideCheck = false // 무게 필요없는 운동이면 false
                }
            }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            if result == true {
                print("서버 운동 저장 성공")
                if let vc = self.view.window?.visibleViewController() {
                    let save = ExerciseCoreData.saveCoreData(info: self.exInfo)
                    if save == true {
                        print("CoreData 저장 완료")
                        configServer.firebaseSave(
                            exName: self.exInfo.exercise,
                            time: self.exInfo.saveTime,
                            uuid: self.exInfo.id.uuidString,
                            date: self.exInfo.date)
                        switch self.type {
                        case "완료":
                            configServer.sendCompleteEx(info: self.exInfo, time: 0, saveTime: self.exInfo.saveTime, subject: self.sendState)
                            return
                            
                        default: // 계획
                            self.indicator.stopAnimating()
                            self.viewModel.saveSuccessExMessage(View: vc)
                            return
                        }
                    } else {
                        print("운동 저장 실패")
                        self.indicator.stopAnimating()
                        self.viewModel.saveFailExMessage(View: vc)
                    }
                } else {
                    print("keyWindow error")
                    self.indicator.stopAnimating()
                    configFirebase.errorReport(type: "saveExerciseVC1.bind", descriptions: "keyWindow error")
                    self.dismiss(animated: true)
                }
            } else {
                print("서버 운동 저장 실패")
                self.indicator.stopAnimating()
                self.showAlert(title: "운동 저장 실패", message: "잠시 후 다시 시도해 주세요.")
            }
        }.store(in: &subscriptions)
        
        sendState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result {
                let update = ExerciseCoreData.updateCoreData(id: self.exInfo.id, entityName: "Anaerobic", saveTime: self.exInfo.saveTime, done: true)
                if update == true {
                    print("운동 완료 후 업데이트 성공")
                    // firebase에 저장하기
                    configFirebase.saveDoneEx(exName: self.exInfo.exercise, set: self.exInfo.set, weight: self.exInfo.weight, count: self.exInfo.count, distance: 0, maxSpeed: 0, avgSpeed: 0, time: 0, date: self.exInfo.date)
                    ExerciseViewController.reloadEx.send(true)
                    self.showAlert(title: "저장 완료", message: "운동이 저장되었습니다.")
                    return
                } else {
                    print("운동 완료 후 업데이트 실패")
                    self.showAlert(title: "운동 저장 실패", message: "잠시 후 다시 시도해 주세요.")
                    return
                }
            } else {
                print("서버 전송 오류, 잠시 후 다시 시도해 주세요.")
                self.showAlert(title: "운동 저장 실패", message: "잠시 후 다시 시도해 주세요.")
            }
        }.store(in: &subscriptions)
    }
}

extension saveExerciseViewController1 {
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
    
    private func saveEx(setNum: Int16, weightNum: Float, countNum: Int16) {
        exInfo = anaerobicExerciseInfo(exercise: exerciseLabel.text ?? "운동 없음", table_Name: tableName, date: ExerciseViewController.pickDate, set: setNum, weight: weightNum, count: countNum, saveTime: Int64(TimeStamp.getCurrentTimestamp()), category: category)
        configServer.sendSaveEx(info: exInfo, subject: serverState)
    }
}

extension saveExerciseViewController1: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // backspace 허용
        if let char = string.cString(using: String.Encoding.utf8) {
            let isBackSpace = strcmp(char, "\\b")
            if isBackSpace == -92 {
                return true
            }
        }
        switch textField.tag {
        case 2:
            guard let text = textField.text else { return false }
            if text.count >= 5 {
                return false
            }
            return true
            
        default:
            guard let text = textField.text else { return false }
            if text.count >= 3 {
                return false
            }
            return true
        }
    }
}
