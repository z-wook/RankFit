//
//  ChangeNickNameViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/21.
//

import UIKit
import Alamofire
import Combine

class ChangeNickNameViewController: UIViewController {

    @IBOutlet var nickName: UITextField!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var saveBtn: UIButton!
    
    let info = getUserInfo()
    let nickNameCheckState = PassthroughSubject<String, Never>()
    let saveUserInfoState = PassthroughSubject<String, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonConfigure()
        nickNamePass()
        savePass()
    }
    
    private func nickNamePass() {
        nickNameCheckState.receive(on: RunLoop.main)
            .sink { result in
                if result == "true" { // 중복검사 통과
                    self.stateLabel.text = "사용 가능한 닉네임 입니다!"
                    self.buttonON()
                } else { // 중복검사 통과 못함, 다른 아이디 입력
                    self.stateLabel.layer.isHidden = false
                    self.stateLabel.text = "이미 존재하는 닉네임입니다."
                }
            }.store(in: &subscriptions)
    }

    private func savePass() {
        saveUserInfoState.receive(on: RunLoop.main)
            .sink { result in
                if result == "true" {
                    // 서버 전송 성공
                    print("======> 성공")
                    UserDefaults.standard.set(self.info.getEmail(), forKey: "Email")
                    UserDefaults.standard.set(self.info.getUserID(), forKey: "UserID")
                    if let nickNameString = self.nickName.text {
                        UserDefaults.standard.set(["nickname": nickNameString, "date": calcDate().after30days()], forKey: "NickName")
                    }
                    UserDefaults.standard.set(self.info.getGender(), forKey: "Gender")
                    UserDefaults.standard.set(["age": self.info.getAge(), "year": self.info.getAgeYear()], forKey: "Age")
                    UserDefaults.standard.set(["weight": self.info.getWeight(), "date": self.info.getWeightDay()], forKey: "Weight")
                    
                    self.navigationController?.popToRootViewController(animated: true)
                } else { // "false"
                    // 서버 전송 실패
                    // 나중에 시도하라는 메시지 전송 후 pop
                    print("======> 실패")
                    return
                }
            }.store(in: &subscriptions)
    }
    
    private func buttonConfigure() {
        nickName.delegate = self
        stateLabel.layer.isHidden = true
        saveBtn.layer.cornerRadius = 20
        saveBtn.layer.shadowColor = UIColor.gray.cgColor
        saveBtn.layer.shadowOpacity = 1.0
        saveBtn.layer.shadowOffset = CGSize.zero
        saveBtn.layer.shadowRadius = 7
        saveBtn.isEnabled = false
        saveBtn.backgroundColor = .darkGray
        checkButton.layer.isHidden = true
        if calcDate().currentDate() < info.getNickNameDays() {
            stateLabel.layer.isHidden = false
            
            // text size reduce
            stateLabel.font = UIFont.systemFont(ofSize: 13)
            stateLabel.text = """
            닉네임 변경 후 30일이 지나지 않아\n
            현재 닉네임을 변경할 수 없습니다.
            """
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
        // 중복 검사
        let parameters: Parameters = [
            "userNickname": nickName.text ?? "정보없음"
        ]
        AF.request("http://rankfit.site/Check.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            // success("true") / success("false")
            
            if let responseBody = response.value {
                self.nickNameCheckState.send(responseBody)
            } else {
                // response.value == nil
                return
            }
        }
    }
    
    @IBAction func sendNickName(_ sender: UIButton) {
        
        let parameters: Parameters = [
            "userID": info.getUserID(), // 플랫폼 고유 아이디
            "userEmail": info.getEmail(), // 이메일
            "userNickname": nickName.text ?? "정보없음",
            "userAge": info.getAge(),
            "userSex": info.getGender(),
            "userWeight": info.getWeight()
        ]
        
        AF.request("http://rankfit.site/RegisterTest.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString { response in
            
            if let responseBody = response.value {
                // 성공하면 조건 추가
                if responseBody == "true" {
                    self.saveUserInfoState.send(responseBody)
                } else { // false
                    // 실패 조건 추가
                }
                
            } else {
                // error 사용자에게 알리기
                return
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension ChangeNickNameViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField.text == "" {
            buttonOff()
            checkButton.layer.isHidden = true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       
        let utf8Char = string.cString(using: .utf8)
        let isBackSpace = strcmp(utf8Char, "\\b")
        
        if isBackSpace == -92 { // 백스페이스면 무조건 true
            buttonOff()
            return true
        }
        else {
            guard let text = textField.text else { return false }
            if text.count >= 8 { // 8자리 초과시 false
                return false
            }
            else {
                if string.hasCharacters() { // 8자리 이하일때 string 검사
                    buttonOff()
                    return true
                }
                else {
                    return false
                }
            }
        }
    }
}

