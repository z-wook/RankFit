//
//  savePlankViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/04.
//

import UIKit
import FirebaseAuth
import Combine

class savePlankViewController: UIViewController {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var viewModel: saveExerciseViewModel!
    var exInfo: anaerobicExerciseInfo!
    let serverState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var tableName: String!
    var minList: [String] = []
    var secList: [String] = []
    var min: String = "0"
    var sec: String = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        bind()
    }
    
    private func configure() {
        exerciseLabel.tintColor = UIColor(named: "link_cyan")
        pickerView.delegate = self
        pickerView.dataSource = self
        setField.delegate = self
        setField.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        saveBtn.layer.cornerRadius = 30
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        
        for i in 0...30 {
            minList.append("\(i)")
        }
        for i in 0...59 {
            secList.append("\(i)")
        }
        
        let defaultRow = 30
        pickerView.selectRow(defaultRow, inComponent: 1, animated: true)
        sec = secList[defaultRow]
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
                        configServer.firebaseSave(
                            exName: self.exInfo.exercise,
                            time: self.exInfo.saveTime,
                            uuid: self.exInfo.id.uuidString,
                            date: self.exInfo.date)
                        self.viewModel.saveSuccessExMessage(View: vc)
                        return
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
            guard let field = setField.text, !field.isEmpty else {
                return viewModel.warningExerciseMessage(ment: "세트를 입력해 주세요.", View: vc)
            }
            let checkedSetNum = viewModel.stringToInt(input: field)
            if checkedSetNum == -1 {
                return viewModel.warningExerciseMessage(ment: "세트를 정확히 입력해 주세요.", View: vc)
            } else if checkedSetNum == 0 {
                return viewModel.warningExerciseMessage(ment: "세트는 0개가 될 수 없습니다.", View: vc)
            } else if checkedSetNum < 0 {
                return viewModel.warningExerciseMessage(ment: "세트는 0개보다 적을 수 없습니다.", View: vc)
            } else if checkedSetNum > 50 {
                return viewModel.warningExerciseMessage(ment: "세트는 50개보다 많을 수 없습니다.", View: vc)
            }
            let minute = 60 * Double(min)!
            let seconds = Double(sec)!
            let time = minute + seconds // 초
            if time <= 0 {
                return viewModel.warningExerciseMessage(ment: "시간은 0초보다 적을 수 없습니다.", View: vc)
            }
            saveEx(setNum: checkedSetNum, exTime: time)
            saveBtn.isEnabled = false
            // prevent modalView dismiss
            self.isModalInPresentation = true
            backgroundView.isHidden = false
            indicator.startAnimating()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension savePlankViewController {
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
    
    private func saveEx(setNum: Int16, exTime: Double) {
        exInfo = anaerobicExerciseInfo(exercise: exerciseLabel.text ?? "운동 없음", table_Name: tableName, date: ExerciseViewController.pickDate, set: setNum, weight: 0, count: 0, exTime: exTime, saveTime: Int64(TimeStamp.getCurrentTimestamp()))
        configServer.sendSaveEx(info: exInfo, subject: serverState)
    }
}

extension savePlankViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return CGFloat(90)
        } else {
            return CGFloat(90)
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return minList[row]
        } else {
            return secList[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.view.endEditing(true)
        if component == 0 {
            min = minList[row]
        } else {
            sec = secList[row]
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return minList.count
        } else {
            return secList.count
        }
    }
}

extension savePlankViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // backspace 허용
        if let char = string.cString(using: String.Encoding.utf8) {
            let isBackSpace = strcmp(char, "\\b")
            if isBackSpace == -92 {
                return true
            }
        }
        
        guard let text = textField.text else { return false }
        if text.count >= 2 {
            return false
        }
        return true
    }
}
