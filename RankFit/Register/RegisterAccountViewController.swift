//
//  RegisterAccountViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/17.
//

import UIKit
import Alamofire
import Combine
import FirebaseAuth
import FirebaseFirestore

class RegisterAccountViewController: UIViewController {
    
    @IBOutlet weak var nickNameField: UITextField!
    @IBOutlet weak var nickNameCheck: UIButton!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailCheck: UIButton!
    @IBOutlet weak var emailState: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    static let emailAuth = PassthroughSubject<String, Never>()
    let loginSubject = PassthroughSubject<String, Never>()
    let nickNameCheckState = PassthroughSubject<Bool, Never>()
    let firebase_info = PassthroughSubject<Bool, Never>()
    let saveUserInfo = PassthroughSubject<Bool, Never>()
    let final = PassthroughSubject<Bool, Never>()
    let final_returnUser = PassthroughSubject<Bool, Never>()
    var cancel: Cancellable?
    var subscriptions = Set<AnyCancellable>()
    
    let viewModel = AuthenticationModel()
    var infomation: userInfo!
    var nickName: String!
    var email: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cancel?.cancel()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func bind() {
        nickNameCheckState.receive(on: RunLoop.main).sink { result in
            if result { // 중복검사 통과
                self.stateLabel.text = "사용 가능한 닉네임 입니다!"
                self.stateLabel.textColor = .label
                self.buttonON()
            } else { // 중복검사 통과 못함, 다른 아이디 입력
                self.stateLabel.layer.isHidden = false
                self.stateLabel.text = "이미 존재하는 닉네임입니다."
                self.stateLabel.textColor = .systemPink
            }
        }.store(in: &subscriptions)
        
        let subject = RegisterAccountViewController.emailAuth.receive(on: RunLoop.main).sink { link in
            guard self.email != nil else { return }
            self.loginSubject.send(link)
        }
        cancel = subject
        
        loginSubject.receive(on: RunLoop.main).sink { link in
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            Auth.auth().signIn(withEmail: self.email, link: link) { result, error in
                if let error = error {
                    print("email auth error: \(error.localizedDescription)")
                    configFirebase.errorReport(type: "RegisterAccountVC.bind", descriptions: error.localizedDescription)
                    self.indicator.stopAnimating()
                    self.showAlert(title: "이메일 인증 실패", description: "이메일 인증에 실패하였습니다. 잠시 후 다시 시도해 주세요.", type: "fail")
                } else {
                    guard let result = result else {
                        configFirebase.errorReport(type: "RegisterAccountVC.bind", descriptions: "result == nil")
                        self.indicator.stopAnimating()
                        self.showAlert(title: "회원가입 실패", description: "잠시 후 다시 회원가입해 주세요.", type: "fail")
                        return
                    }
                    // 저장된 파일 있는지 확인 -> 없으면 회원가입 / 있으면 정보 가져오기
                    let UID = result.user.uid
                    let db = Firestore.firestore()
                    db.collection("baseInfo").document(UID).getDocument { snapshot, error in
                        if let error = error {
                            print("error: \(error.localizedDescription)")
                            configFirebase.errorReport(type: "LoginVC.bind", descriptions: error.localizedDescription)
                            self.indicator.stopAnimating()
                            self.showAlert(title: "회원가입 실패", description: "잠시 후 다시 회원가입해 주세요.", type: "fail")
                        } else {
                            guard let snapshot = snapshot else {
                                configFirebase.errorReport(type: "LoginVC.bind", descriptions: "snapshot == nil")
                                self.indicator.stopAnimating()
                                self.showAlert(title: "회원가입 실패", description: "잠시 후 다시 회원가입해 주세요.", type: "fail")
                                return
                            }
                            guard let data = snapshot.data() else {
                                // 등록된 정보 없는 경우 회원가입
                                // userinfo 객체 넘기기
                                let info = userInfo(gender: self.infomation.gender, birth: self.infomation.birth, weight: self.infomation.weight, uid: result.user.uid, email: self.email, nickName: self.nickName)
                                self.viewModel.userInfoData.send(info)
                                return
                            }
                            // 등록된 정보가 있다면 회원가입된 유저이므로 정보 가져와서 keychain에 저장
                            let birth = data["Birth"] as! String
                            let gender = data["Gender"] as! Int
                            let weight = data["Weight"] as! Int
                            let nickName = data["nickName"] as! String
                            
                            let calc = calcDate()
                            saveUserData.setKeychain(self.email, forKey: .Email)
                            saveUserData.setKeychain(UID, forKey: .UID)
                            saveUserData.setKeychain(gender, forKey: .Gender)
                            saveUserData.setKeychain(birth, forKey: .Birth)
                            
                            saveUserData.setKeychain(nickName, forKey: .NickName)
                            UserDefaults.standard.set(calc.after30days(), forKey: "nick_date")
                            
                            saveUserData.setKeychain(weight, forKey: .Weight)
                            UserDefaults.standard.set(calc.after1Day(), forKey: "weight_date")
                            UserDefaults.standard.removeObject(forKey: "login") // 혹시 login 뷰로 넘어가지 않게 하기위해
                            // Firebase, 서버에서 사진과 운동 가져와서 저장하기 + Token값 전송
                            ReturnToRankFit().initiate(nickName: nickName, Subject: self.final_returnUser)
                        }
                    }
                }
            }
        }.store(in: &subscriptions)
        
        viewModel.userInfoData.receive(on: RunLoop.main).sink { userinfo in
            // firebase DB 저장
            guard userinfo != nil else { return }
            self.viewModel.sendFirebaseDB(subject: self.firebase_info)
        }.store(in: &subscriptions)
        
        firebase_info.receive(on: RunLoop.main).sink { result in
            if result {
                // 서버에 info 전송
                self.viewModel.sendServer(subject: self.saveUserInfo)
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "회원가입 실패", description: "잠시 후 다시 회원가입해 주세요.", type: "fail")
            }
        }.store(in: &subscriptions)
        
        saveUserInfo.receive(on: RunLoop.main).sink { result in
            if result {
                self.viewModel.saveKeyChain(subject: self.final)
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "회원가입 실패", description: "잠시 후 다시 회원가입해 주세요.", type: "fail")
            }
        }.store(in: &subscriptions)
        
        final.receive(on: RunLoop.main).sink { result in
            if result {
                UserDefaults.standard.set(true, forKey: "login")
                checkRegister.shared.setIsNotNewUser()
                SettingViewController.reloadProfile.send(true)
                self.indicator.stopAnimating()
                self.showAlert(title: "회원가입 완료", description: "🎉 랭크핏에 오신 것을 환영합니다. 🎉", type: "welcome")
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "회원가입 실패", description: "잠시 후 다시 회원가입해 주세요.", type: "fail")
            }
        }.store(in: &subscriptions)
        
        final_returnUser.receive(on: RunLoop.main).sink { result in
            if result {
                checkRegister.shared.setIsNotNewUser()
                SettingViewController.reloadProfile.send(true)
                self.indicator.stopAnimating()
                self.showAlert(title: "🎉 복귀를 환영합니다. 🎉", description: "회원가입 정보가 있기 때문에 회원 정보를 가져옵니다.", type: "welcome")
            }
        }.store(in: &subscriptions)
    }
    
    @IBAction func nickNameCheck(_ sender: UIButton) {
        guard let nickNameStr = nickNameField.text else { return }
        // 키보드 내리기
        view.endEditing(true)
        if SlangFilter().nickNameFilter(nickName: nickNameStr) {
            self.nickName = nickNameStr
            let parameters: Parameters = [
                "userNickname": nickNameStr
            ]
            AF.request("http://rankfit.site/Check.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString { response in
                // success("true") / success("false")
                if let responseBody = response.value {
                    if responseBody == "true" {
                        self.nickNameCheckState.send(true)
                    } else {
                        self.nickNameCheckState.send(false)
                    }
                } else {
                    print("error: response.value == nil")
                    configFirebase.errorReport(type: "RegisterAccountVC.nickNameCheck", descriptions: "response.value == nil", server: response.debugDescription)
                    self.showAlert(title: "서버와 통신오류", description: "잠시 후 다시 시도해 주세요.", type: "fail")
                }
            }
        } else { // 비속어 포함
            stateLabel.textColor = .red
            stateLabel.layer.isHidden = false
            stateLabel.text = "비속어, 음란성 단어는 사용할 수 없습니다."
        }
    }
    
    @IBAction func sendEmail(_ sender: UIButton) {
        guard let email = emailField.text else { return }
        emailCheck.layer.isHidden = true
        // 키보드 내리기
        view.endEditing(true)
        // 이메일 검사
        let result = isValidEmail(email: email)
        if result {
            let actionCodeSettings = ActionCodeSettings()
            actionCodeSettings.url = URL(string: Store.shared.firebaseURL + "\(email)")
            actionCodeSettings.handleCodeInApp = true
            actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
            
            Auth.auth().sendSignInLink(toEmail: email,
                                       actionCodeSettings: actionCodeSettings) { error in
                if let error = error {
                    let error = error.localizedDescription
                    if error == "The user account has been disabled by an administrator." {
                        self.showAlert(title: "계정 사용 중지됨", description: "귀하의 계정이 사용 중지되었습니다. 문의사항은 관리자에게 해주세요.", type: "auth")
                        return
                    }
                    print("Email Not Sent: \(error)")
                    configFirebase.errorReport(type: "RegisterAccountVC.sendEmail", descriptions: error)
                    self.showAlert(title: "인증 메일 발송 실패", description: "잠시 후 다시 시도해 주세요.", type: "email")
                } else {
                    print("Email Sent")
                    self.email = email
                    self.emailState.text = "인증 메일이 발송되었습니다. 본인 인증을 완료해 주세요."
                    self.emailState.textColor = .systemPink
                    self.nickNameField.isEnabled = false
                }
            }
        } else {
            showAlert(title: "인증 메일 발송 실패", description: "올바른 이메일 형식이 아닙니다.", type: "email")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension RegisterAccountViewController {
    // code by chatGPT
    private func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
    
    private func showAlert(title: String, description: String, type: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            if type == "email" { return }
            else if type == "fail" {
                self.navigationController?.popViewController(animated: true)
                return
            } else if type == "auth" {
                self.navigationController?.popToRootViewController(animated: true)
                return
            } else {
                // Firebase에서 사진이 언제 저장 완료될지 모르기 때문에 1초 후 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    DiaryViewController.reloadDiary.send(true)
                }
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func configure() {
        nickNameField.tag = 0
        emailField.tag = 1
        nickNameField.delegate = self
        emailField.delegate = self
        stateLabel.layer.isHidden = true
        nickNameCheck.layer.isHidden = true
        emailField.isEnabled = false
        emailCheck.layer.isHidden = true
        backgroundView.isHidden = true
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func buttonON() {
        nickNameCheck.layer.isHidden = true
        stateLabel.layer.isHidden = false
        emailField.isEnabled = true
        emailCheck.layer.isHidden = false
    }
    
    private func buttonOff() {
        stateLabel.layer.isHidden = true
        emailField.isEnabled = false
        emailCheck.layer.isHidden = true
    }
}

extension RegisterAccountViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        switch textField.tag {
        case 0: // nickNameField
            if let text = textField.text {
                if text == "" {
                    nickNameCheck.layer.isHidden = true
                    buttonOff()
                } else {
                    nickNameCheck.layer.isHidden = false
                    buttonOff()
                    if text.count > 8 {
                        nickNameCheck.layer.isHidden = true
                        buttonOff()
                        stateLabel.layer.isHidden = false
                        stateLabel.text = "닉네임은 8글자까지 설정할 수 있습니다."
                        stateLabel.textColor = .red
                    } else {
                        stateLabel.layer.isHidden = true
                    }
                }
            }
            
        default: // emailField
            if textField.text == email {
                emailCheck.layer.isHidden = true
                emailState.text = "인증 메일이 발송되었습니다. 본인 인증을 완료해 주세요."
                emailState.textColor = .systemPink
                return
            }
            if textField.text == "" {
                emailCheck.layer.isHidden = true
            } else {
                emailCheck.layer.isHidden = false
                emailState.text = "※ 회원가입 시 사용한 이메일을 입력해 주세요."
                emailState.textColor = .label
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField.tag {
        case 0: // nickNameField
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
            
        default: // emailField
            return true
        }
    }
}

extension String {
    func hasCharacters() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9]$", options: .caseInsensitive)
            if let _ = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, self.count)){
                return true
            }
        } catch {
            print(error.localizedDescription)
            configFirebase.errorReport(type: "RegisterAccountVC.hasCharacters", descriptions: error.localizedDescription)
            return false
        }
        return false
    }
}
