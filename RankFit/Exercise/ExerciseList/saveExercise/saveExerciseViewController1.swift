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
    
    var viewModel: saveExerciseViewModel!
    var exInfo: anaerobicExerciseInfo!
    var hideCheck: Bool = true // 무게가 필요있는 운동이면 true
    let serverState = PassthroughSubject<Bool, Never>()
    let firebaseState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var tableName: String!
    
    // getTopViewController
    let keyWindow = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive })
        .map({ $0 as? UIWindowScene })
        .compactMap({ $0 })
        .first?.windows
        .filter({ $0.isKeyWindow }).first
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    private func configure() {
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        saveBtn.layer.cornerRadius = 30
        setField.delegate = self
        weightField.delegate = self
        countField.delegate = self
        weightField.tag = 1
    }
    
    private func bind() {
        viewModel.$DetailItem
            .receive(on: RunLoop.main)
            .sink { info in
                self.exerciseLabel.text = info?.exerciseName
                self.tableName = info?.table_name
                if info?.group == 2 {
                    self.weightField.isHidden = true
                    self.weightLabel.isHidden = true
                    self.hideCheck = false // 무게 필요없는 운동이면 false
                }
            }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            if result == true {
                print("서버 운동 저장 성공")
                SendAnaerobicEx.firebaseSave(
                    exName: self.exInfo.exercise,
                    time: self.exInfo.saveTime,
                    uuid: "\(self.exInfo.id)",
                    date: self.exInfo.date,
                    subject: self.firebaseState)
            } else {
                print("서버 운동 저장 실패")
                self.showAlert()
            }
        }.store(in: &subscriptions)
        
        firebaseState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result == true {
                print("Firebase 저장 성공")
                if let vc = self.keyWindow?.visibleViewController {
                    let save = ExerciseCoreData.saveCoreData(info: self.exInfo)
                    if save == true {
                        print("CoreData 저장 완료")
                        self.viewModel.saveSuccessExMessage(View: vc)
                    } else {
                        print("운동 저장 실패")
                        self.viewModel.saveFailExMessage(View: vc)
                    }
                } else {
                    print("keyWindow error")
                    configFirebase.errorReport(type: "saveExerciseVC1.bind", descriptions: "keyWindow error")
                    self.dismiss(animated: true)
                }
            } else {
                print("Firebase 저장 실패")
                SendAnaerobicEx.sendDeleteEx(info: self.exInfo, subject: nil)
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
        if let vc = keyWindow?.visibleViewController {
            guard let field1 = setField.text, !field1.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "세트를 입력하세요.", View: vc)
            }
            let checkedSetNum = viewModel.stringToInt(input: field1)
            if checkedSetNum == -1 {
                return viewModel.warningExerciseMessage(ment: "세트를 정확히 입력해 주세요.", View: vc)
            }
            if checkedSetNum == 0 {
                return viewModel.warningExerciseMessage(ment: "세트는 0개가 될 수 없습니다.", View: vc)
            }
            if checkedSetNum < 0 {
                return viewModel.warningExerciseMessage(ment: "세트는 0개 보다 적을 수 없습니다.", View: vc)
            }

            guard let field2 = countField.text, !field2.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "개수를 입력하세요.", View: vc)
            }
            let checkCountNum = viewModel.stringToInt(input: field2)
            if checkCountNum == -1 {
                return viewModel.warningExerciseMessage(ment: "개수를 정확히 입력해 주세요.", View: vc)
            }
            if checkCountNum == 0 {
                return viewModel.warningExerciseMessage(ment: "개수는 0개가 될 수 없습니다.", View: vc)
            }
            if checkCountNum < 0 {
                return viewModel.warningExerciseMessage(ment: "개수는 0개 보다 적을 수없습니다.", View: vc)
            }
            
            var weightNum: Float = 0.0 // 무게 필요 없으면 0.0으로 저장
            // 무게가 필요 있는 운동의 경우
            if hideCheck {
                guard let field3 = weightField.text, !field3.isEmpty else {
                    return viewModel.warningExerciseMessage(ment: "무게를 입력하세요.", View: vc)
                }
                let checkedWeightNum = viewModel.stringToFloat(input: field3)
                if checkedWeightNum == -1 {
                    return viewModel.warningExerciseMessage(ment: "무게를 정확히 입력해 주세요.", View: vc)
                }
                if checkedWeightNum <= 0 {
                    viewModel.warningExerciseMessage(ment: "무게는 0kg 보다 적을 수 없습니다.", View: vc)
                    return
                }
                if checkedWeightNum >= 1000 {
                    return viewModel.warningExerciseMessage(ment: "무게는 1000kg를 넘을 수 없습니다.", View: vc)
                }
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
    private func showAlert() {
        let alert = UIAlertController(title:"저장 실패", message: "잠시 후 다시 시도해 주세요.", preferredStyle: .alert)
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
        exInfo = anaerobicExerciseInfo(exercise: exerciseLabel.text ?? "운동 없음", table_Name: tableName, date: ExerciseViewController.pickDate, set: setNum, weight: weightNum, count: countNum, saveTime: Int64(TimeStamp.getCurrentTimestamp()))
        SendAnaerobicEx.sendSaveEx(info: exInfo, subject: serverState)
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
        case 1:
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
