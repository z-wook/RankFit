//
//  InputInfoViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/17.
//

import UIKit
import Alamofire

class InputInfoViewController: UIViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    
    var type: String!
    var list: [String] = []
    var pickElement: String!
    let userInfo = getSavedDateInfo()
    let calc = calcDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonConfigure()
        configPickerView()
    }

    private func buttonOff() {
        messageLabel.layer.isHidden = true
        saveBtn.isEnabled = false
        saveBtn.backgroundColor = .darkGray
    }
    
    private func buttonConfigure() {
        saveBtn.layer.cornerRadius = 20
        saveBtn.layer.shadowColor = UIColor.gray.cgColor
        saveBtn.layer.shadowOpacity = 1.0
        saveBtn.layer.shadowOffset = CGSize.zero
        saveBtn.layer.shadowRadius = 7
    }
    
    func configure(type: String) {
        self.type = type
    }

    private func configPickerView() {
        // pickerView 초기값 세팅
        pickerView.delegate = self
        pickerView.dataSource = self
        var defaultRow: Int!
        
        switch type {
        case "나이":
            self.navigationItem.title = "나이 설정"
            descriptionLabel.text = "변경할 나이를 입력해 주세요."
            for i in 10...100 {
                list.append("\(i)")
            }
            let age = saveUserData.getKeychainIntValue(forKey: .Age) ?? 35
            defaultRow = age - 10
            pickerView.selectRow(defaultRow, inComponent: 0, animated: true)
            pickElement = list[defaultRow]
            
            let year = userInfo.getAgeDate()
            if (calc.currentYear() >= year && year != "-1") {
                // 변경 가능
                messageLabel.layer.isHidden = true
                saveBtn.isEnabled = true
            } else {
                messageLabel.text = """
                현재 나이를 변경할 수 없습니다. \n
                1월 1일이 지나면 변경할 수 있습니다.
                """
                saveBtn.isEnabled = false
                saveBtn.backgroundColor = .darkGray
            }
            
        case "몸무게":
            self.navigationItem.title = "몸무게 설정"
            descriptionLabel.text = "변경할 몸무게를 입력해 주세요."
            for i in 35...150 {
                list.append("\(i)")
            }
            let weight = saveUserData.getKeychainIntValue(forKey: .Weight) ?? 100
            defaultRow = weight - 35
            pickerView.selectRow(defaultRow, inComponent: 0, animated: true)
            pickElement = list[defaultRow]
            
            let day = userInfo.getWeightDate()
            if (calc.currentDate() >= day && day != "-1") {
                // 변경 가능
                messageLabel.layer.isHidden = true
                saveBtn.isEnabled = true
            } else {
                messageLabel.text = """
                현재 몸무게를 변경할 수 없습니다. \n
                내일 변경할 수 있습니다.
                """
                saveBtn.isEnabled = false
                saveBtn.backgroundColor = .darkGray
            }
            
        default:
            descriptionLabel.text = "현재 변경할 수 없습니다."
            pickerView.layer.isHidden = true
            messageLabel.text = "현재 변경할 수 없습니다."
            saveBtn.isEnabled = false
            saveBtn.backgroundColor = .darkGray
            return
        }
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        let intElement = Int(pickElement) ?? -1
        sendServer(type: type, element: intElement)
    }
    
    func sendServer(type: String , element: Int) {
        let id = saveUserData.getKeychainStringValue(forKey: .UserID) ?? "정보없음"
        let email = saveUserData.getKeychainStringValue(forKey: .Email) ?? "정보없음"
        let nickName = saveUserData.getKeychainStringValue(forKey: .NickName) ?? "정보없음"
        var age = saveUserData.getKeychainIntValue(forKey: .Age) ?? 1
        let gender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        var weight = saveUserData.getKeychainIntValue(forKey: .Weight) ?? 1
        
        switch type {
        case "나이":
            age = element
        case "몸무게":
            weight = element
        default: return
        }
        
        let parameters: Parameters = [
            "userID": id,   // 플랫폼 고유 아이디
            "userEmail": email,
            "userNickname": nickName,
            "userAge": age,
            "userSex": gender,
            "userWeight": weight
        ]

        AF.request("http://rankfit.site/Register.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
            response in
            print("response: \(response)")
            if let responseBody = response.value {                
                if responseBody == "true" {
                    let calc = calcDate()
                    
                    switch type {
                    case "나이":
                        // 키체인은 덮어쓰기가 안되기 때문에 기존에 저장된 값 삭제 후 새로운 값 저장
                        saveUserData.removeKeychain(forKey: .Age)
                        saveUserData.setKeychain(age, forKey: .Age)
                        UserDefaults.standard.set(calc.nextYear(), forKey: "age_date")
                        
                        // 여기서 나이 변경되면 알려주기
//                        MyProfileViewController.userWeight.send(weight)
                        
                    case "몸무게":
                        // 키체인은 덮어쓰기가 안되기 때문에 기존에 저장된 값 삭제 후 새로운 값 저장
                        saveUserData.removeKeychain(forKey: .Weight)
                        saveUserData.setKeychain(weight, forKey: .Weight)
                        UserDefaults.standard.set(calc.after1Day(), forKey: "weight_date")
                        MyProfileViewController.userWeight.send(weight)
                        
                    default: return
                    }
                } else {
                    // responseBody == "false"
                    // error 알리기
                    return
                }
                self.navigationController?.popViewController(animated: true)
                
                
            } else {
                
                // error 사용자에게 알리기
                return
            }
        }
    }
    
}

extension InputInfoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // pickerView에 담긴 아이템의 컴포넌트 개수
    // pickerView는 여러 개의 wheel이 있을 수 있다.
    // 여기서는 1개의 wheel을 가진 pickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickElement = list[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        if type == "나이" {
            return NSAttributedString(string: list[row] + "세", attributes: [.foregroundColor:UIColor.label])
        }
        else if type == "몸무게" {
            return NSAttributedString(string: list[row] + "kg", attributes: [.foregroundColor:UIColor.label])
        }
        else {
            return NSAttributedString(string: list[row], attributes: [.foregroundColor:UIColor.label])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
}
