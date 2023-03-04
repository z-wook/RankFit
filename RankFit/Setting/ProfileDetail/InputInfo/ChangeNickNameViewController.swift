//
//  ChangeNickNameViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/21.
//

import UIKit
import Combine

class ChangeNickNameViewController: UIViewController {

    @IBOutlet var nickName: UITextField!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var saveBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let viewModel = InputInfoViewModel()
    let info = getSavedDateInfo()
    let nickNameCheckState = PassthroughSubject<Bool, Never>()
    let fireState = PassthroughSubject<Bool, Never>()
    let serverState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isUserInteractionEnabled = true
    }
    
    private func bind() {
        nickNameCheckState.receive(on: RunLoop.main).sink { result in
            if result {
                self.stateLabel.text = "사용 가능한 닉네임 입니다!"
                self.buttonON()
            } else {
                self.stateLabel.layer.isHidden = false
                self.stateLabel.text = "이미 존재하는 닉네임입니다."
            }
        }.store(in: &subscriptions)
        
        fireState.receive(on: RunLoop.main).sink { result in
            if result {
                let nickName = self.nickName.text!
                self.viewModel.sendNickName(nickName: nickName, subject: self.serverState)
            } else {
                self.indicator.stopAnimating()
                self.showAlert()
            }
        }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result {
                // 기존에 저장되있던 값 삭제 keyChain은 덮어쓰기 못함
                saveUserData.removeKeychain(forKey: .NickName)
                guard let nickNameStr = self.nickName.text else {
                    configFirebase.errorReport(type: "ChangeNickNameVC.subject", descriptions: "nickName.text == nil")
                    return
                }
                saveUserData.setKeychain(nickNameStr, forKey: .NickName)
                UserDefaults.standard.set(calcDate().after30days(), forKey: "nick_date")
                SettingViewController.reloadProfile.send(true)
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.showAlert()
            }
        }.store(in: &subscriptions)
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "닉네임 변경 오류", message: "잠시 후 다시 시도해 주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func configure() {
        nickName.delegate = self
        stateLabel.layer.isHidden = true
        saveBtn.layer.cornerRadius = 20
        saveBtn.isEnabled = false
        saveBtn.backgroundColor = .darkGray
        checkButton.layer.isHidden = true
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        if calcDate().currentDate() < info.getNickNameDate() {
            stateLabel.layer.isHidden = false
            // text size reduce
            stateLabel.font = UIFont.systemFont(ofSize: 13)
            stateLabel.text = "닉네임 변경 후 30일이 지나지 않아 현재 닉네임을 변경할 수 없습니다."
            nickName.isEnabled = false
        }
    }

    private func buttonON() {
        checkButton.layer.isHidden = true
        stateLabel.layer.isHidden = false
        saveBtn.isEnabled = true
        saveBtn.backgroundColor = .systemIndigo
    }
    
    private func buttonOff() {
        checkButton.layer.isHidden = false
        stateLabel.layer.isHidden = true
        saveBtn.isEnabled = false
        saveBtn.backgroundColor = .darkGray
    }
    
    @IBAction func nickNameCheck(_ sender: UIButton) {
        guard let nickName = nickName.text else { return }
        // 키보드 내리기
        view.endEditing(true)
        if SlangFilter().nickNameFilter(nickName: nickName) {
            viewModel.nickNameCheck(nickName: nickName, subject: nickNameCheckState)
        } else { // 비속어 포함
            stateLabel.textColor = .red
            stateLabel.layer.isHidden = false
            stateLabel.text = "비속어, 음란성 단어는 사용할 수 없습니다."
            checkButton.layer.isHidden = true
        }
    }
    
    @IBAction func sendNickName(_ sender: UIButton) {
        guard let nickName = nickName.text else { return }
        backgroundView.layer.isHidden = false
        indicator.startAnimating()
        self.tabBarController?.tabBar.isUserInteractionEnabled = false
        configFirebase.updateNickName(nickName: nickName, subject: fireState)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension ChangeNickNameViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            if text == "" {
                buttonOff()
                checkButton.layer.isHidden = true
            } else {
                buttonOff()
                checkButton.layer.isHidden = false
                
                if text.count > 8 {
                    buttonOff()
                    checkButton.layer.isHidden = true
                    stateLabel.layer.isHidden = false
                    stateLabel.text = "닉네임은 8글자까지 설정할 수 있습니다."
                    stateLabel.textColor = .red
                } else {
                    stateLabel.layer.isHidden = true
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let utf8Char = string.cString(using: .utf8)
        let isBackSpace = strcmp(utf8Char, "\\b")
        if isBackSpace == -92 { // 백스페이스면 무조건 true
            buttonOff()
            return true
        } else {
            // 8자리 이하일때 string 검사
            if string.hasCharacters() { return true }
            else { return false }
        }
    }
}
