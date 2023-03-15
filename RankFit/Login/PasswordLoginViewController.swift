//
//  PasswordLoginViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/14.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Combine

class PasswordLoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var eyeBtn: UIButton!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let finalSubject = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        bind()
    }
    
    @IBAction func veiledBtn(_ sender: UIButton) {
        // 보안 설정 반전
        passwordField.isSecureTextEntry.toggle()
        // 버튼 선택 상태 반전
        eyeBtn.isSelected.toggle()
        let eyeImg = eyeBtn.isSelected ? "eye" : "eye.slash"
        DispatchQueue.main.async {
            sender.setImage(UIImage(systemName: eyeImg), for: .normal)
        }
    }
    
    @IBAction func login(_ sender: UIButton) {
        view.endEditing(true) // 키보드 내리기
        guard let email = emailField.text else {
            showAlert(title: "로그인 실패", description: "이메일을 입력해 주세요.", type: "default")
            return
        }
        guard let password = passwordField.text else {
            showAlert(title: "로그인 실패", description: "비밀번호를 입력해 주세요.", type: "default")
            return
        }
        if password.count < 6 {
            showAlert(title: "로그인 실패", description: "비밀번호 6자리 이상을 입력해 주세요.", type: "default")
            return
        }
        // 이메일 검사
        let result = isValidEmail(email: email)
        if result {
            backgroundView.isHidden = false
            indicator.startAnimating()
            passwordLogin(email: email, pw: password)
            return
        } else {
            showAlert(title: "로그인 실패", description: "올바른 이메일 형식이 아닙니다.", type: "default")
            return
        }
    }
    
    private func configure() {
        navigationItem.largeTitleDisplayMode = .never
        emailField.delegate = self
        passwordField.delegate = self
        emailField.tag = 0
        passwordField.tag = 1
        backgroundView.isHidden = true
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        
        // 뷰 전체 높이 길이
        let screenHeight = UIScreen.main.bounds.size.height
        if screenHeight == 568 { // 4 inch
            setKeyboardObserver()
        }
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if self.view.window?.frame.origin.y == 0 {
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                if passwordField.isEditing {
                    // 뷰를 키보드 높이만큼 올림
                    UIView.animate(withDuration: 1) {
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
                UIView.animate(withDuration: 1) {
                    self.view.window?.frame.origin.y += keyboardHeight
                }
            }
        }
    }
    
    private func bind() {
        finalSubject.receive(on: RunLoop.main).sink { result in
            if result {
                checkRegister.shared.setIsNotNewUser()
                SettingViewController.reloadProfile.send(true)
                self.indicator.stopAnimating()
                self.showAlert(title: "🎉 복귀를 환영합니다. 🎉", description: "최근 6개월간 완료한 운동을 저장했습니다.", type: "welcome")
            }
        }.store(in: &subscriptions)
    }
    
    private func passwordLogin(email: String, pw: String) {
        Auth.auth().signIn(withEmail: email, password: pw) { result, error in
            if let error = error {
                let error = error.localizedDescription
                print("error: \(error)")
                if error == "The user account has been disabled by an administrator." {
                    self.showAlert(title: "계정 사용 중지됨", description: "귀하의 계정이 사용 중지되었습니다. 문의사항은 관리자에게 해주세요.", type: "auth")
                    return
                } else if error == "The password is invalid or the user does not have a password." {
                    self.showAlert(title: "비밀번호 오류", description: "잘못된 비밀번호이거나 비밀번호를 설정하지 않았습니다.", type: "login")
                    return
                } else if error == "There is no user record corresponding to this identifier. The user may have been deleted." {
                    self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다. 회원가입하지 않았거나, 가입 시 사용한 이메일이 아닙니다.", type: "login")
                    return
                } else {
                    configFirebase.errorReport(type: "PasswordLoginVC.passwordLogin", descriptions: error)
                    self.showAlert(title: "로그인 실패", description: "잠시 후 다시 로그인해 주세요", type: "auth")
                    return
                }
            } else {
                guard let result = result else {
                    self.showAlert(title: "로그인 실패", description: "잠시 후 다시 로그인해 주세요", type: "auth")
                    return
                }
                let UID = result.user.uid
                let db = Firestore.firestore()
                db.collection("baseInfo").document(UID).getDocument { snapshot, error in
                    if let error = error {
                        print("error: \(error.localizedDescription)")
                        configFirebase.errorReport(type: "LoginVC.bind", descriptions: error.localizedDescription)
                        self.showAlert(title: "로그인 실패", description: "잠시 후 다시 로그인해 주세요.", type: "auth")
                    } else {
                        guard let snapshot = snapshot else {
                            self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다.", type: "auth")
                            return
                        }
                        guard let data = snapshot.data() else {
                            self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다.", type: "auth")
                            return
                        }
                        let birth = data["Birth"] as! String
                        let gender = data["Gender"] as! Int
                        let weight = data["Weight"] as! Int
                        let nickName = data["nickName"] as! String
                        
                        let calc = calcDate()
                        saveUserData.setKeychain(email, forKey: .Email)
                        saveUserData.setKeychain(UID, forKey: .UID)
                        saveUserData.setKeychain(gender, forKey: .Gender)
                        saveUserData.setKeychain(birth, forKey: .Birth)
                        
                        saveUserData.setKeychain(nickName, forKey: .NickName)
                        UserDefaults.standard.set(calc.after30days(), forKey: "nick_date")
                        
                        saveUserData.setKeychain(weight, forKey: .Weight)
                        UserDefaults.standard.set(calc.after1Day(), forKey: "weight_date")
                        UserDefaults.standard.set(true, forKey: "login")
                        if checkRegister().isNewUser() { // 복귀유저라면
                            // Firebase, 서버에서 사진과 운동 가져와서 저장하기 + Token값 전송
                            ReturnToRankFit().initiate(nickName: nickName, Subject: self.finalSubject)
                        } else {
                            SettingViewController.reloadProfile.send(true)
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    // code by chatGPT
    private func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
    
    private func showAlert(title: String, description: String, type: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            switch type {
            case "auth":
                self.navigationController?.popToRootViewController(animated: true)
                return
                
            case "welcome":
                // Firebase에서 사진이 언제 저장 완료될지 모르기 때문에 3초 후 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    DiaryViewController.reloadDiary.send(true)
                }
                self.navigationController?.popToRootViewController(animated: true)
                return
                
            default:
                self.backgroundView.isHidden = true
                self.indicator.stopAnimating()
                return
            }
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension PasswordLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 1 {
            let asciiSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?!@$&") // ASCII capable 문자열셋
            if let _ = string.rangeOfCharacter(from: asciiSet.inverted) { // 입력된 문자열에 ASCII capable 이외의 문자가 있는 경우
                return false // 입력 거부
            }
            return true // 입력 허용
        } else { return true }
    }
}
