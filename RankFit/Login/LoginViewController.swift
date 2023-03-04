//
//  LoginViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/27.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Combine

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailCheck: UIButton!
    @IBOutlet weak var emailState: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    static let emailAuth = PassthroughSubject<String, Never>()
    let loginSubject = PassthroughSubject<String, Never>()
    let finalSubject = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var cancel: Cancellable?
    var email: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cancel?.cancel()
    }
    
    private func configure() {
        navigationItem.largeTitleDisplayMode = .never
        emailField.delegate = self
        emailCheck.layer.isHidden = true
        backgroundView.isHidden = true
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
    }
    
    private func bind() {
        let subject = LoginViewController.emailAuth.receive(on: RunLoop.main).sink { link in
            print("link1: \(link)")
            guard self.email != nil else { return }
            self.loginSubject.send(link)
        }
        cancel = subject
        
        loginSubject.receive(on: RunLoop.main).sink { link in
            print("link2: \(link)")
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            UserDefaults.standard.removeObject(forKey: "login")
            Auth.auth().signIn(withEmail: self.email, link: link) { result, error in
                if let error = error {
                    print("email auth error: \(error.localizedDescription)")
                    configFirebase.errorReport(type: "LoginVC.bind", descriptions: error.localizedDescription)
                    self.indicator.stopAnimating()
                    self.showAlert(title: "이메일 인증 실패", description: "이메일 인증에 실패하였습니다. 잠시 후 다시 시도해 주세요.", type: "login")
                } else {
                    guard let result = result else {
                        configFirebase.errorReport(type: "LoginVC.bind", descriptions: "result == nil")
                        self.indicator.stopAnimating()
                        self.showAlert(title: "로그인 실패", description: "잠시 후 다시 로그인해 주세요.", type: "login")
                        return
                    }
                    // firebase DB에서 정보 가져온 후 키체인에 저장
                    let UID = result.user.uid
                    let db = Firestore.firestore()
                    db.collection("baseInfo").document(UID).getDocument { snapshot, error in
                        if let error = error {
                            print("error: \(error.localizedDescription)")
                            configFirebase.errorReport(type: "LoginVC.bind", descriptions: error.localizedDescription)
                            self.indicator.stopAnimating()
                            self.showAlert(title: "로그인 실패", description: "잠시 후 다시 로그인해 주세요.", type: "login")
                        } else {
                            guard let snapshot = snapshot else {
                                // 등록된 정보 없는 경우 방급 가입된 계정 즉시 삭제
                                let user = Auth.auth().currentUser
                                if let user = user {
                                    user.delete { error in
                                        if let error = error {
                                            print("error: " + error.localizedDescription)
                                            configFirebase.errorReport(type: "LoginVC.loginErrorAlert", descriptions: "\(String(describing: user.email))" + error.localizedDescription)
                                            self.indicator.stopAnimating()
                                            self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다. 회원가입하지 않았거나, 가입 시 사용한 이메일이 아닙니다.", type: "default")
                                            return
                                        } else {
                                            print("방금 등록된 계정 삭제 완료")
                                            self.indicator.stopAnimating()
                                            self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다. 회원가입하지 않았거나, 가입 시 사용한 이메일이 아닙니다.", type: "default")
                                            return
                                        }
                                    }
                                }
                                configFirebase.errorReport(type: "LoginVC.bind", descriptions: "snapshot == nil")
                                self.indicator.stopAnimating()
                                self.showAlert(title: "로그인 실패", description: "잠시 후 다시 로그인해 주세요.", type: "login")
                                return
                            }
                            guard let data = snapshot.data() else {
                                // 등록된 정보 없는 경우 방급 가입된 계정 즉시 삭제
                                let user = Auth.auth().currentUser
                                if let user = user {
                                    user.delete { error in
                                        if let error = error {
                                            print("error: " + error.localizedDescription)
                                            configFirebase.errorReport(type: "LoginVC.loginErrorAlert", descriptions: "\(String(describing: user.email))" + error.localizedDescription)
                                            self.indicator.stopAnimating()
                                            self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다. 회원가입하지 않았거나, 가입 시 사용한 이메일이 아닙니다.", type: "default")
                                            return
                                        } else {
                                            print("방금 등록된 계정 삭제 완료")
                                            self.indicator.stopAnimating()
                                            self.showAlert(title: "로그인 실패", description: "등록된 정보가 없습니다. 회원가입하지 않았거나, 가입 시 사용한 이메일이 아닙니다.", type: "default")
                                            return
                                        }
                                    }
                                }
                                return
                            }
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
                            UserDefaults.standard.set(true, forKey: "login")
                            if checkRegister().isNewUser() { // 복귀유저라면
                                // Firebase, 서버에서 사진과 운동 가져와서 저장하기 + Token값 전송
                                ReturnToRankFit().initiate(nickName: nickName, Subject: self.finalSubject)
                            } else {
                                SettingViewController.reloadProfile.send(true)
                                self.indicator.stopAnimating()
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                }
            }
        }.store(in: &subscriptions)
        
        finalSubject.receive(on: RunLoop.main).sink { result in
            if result {
                checkRegister.shared.setIsNotNewUser()
                SettingViewController.reloadProfile.send(true)
                self.indicator.stopAnimating()
                self.cancel?.cancel()
                self.showAlert(title: "🎉 복귀를 환영합니다. 🎉", description: "최근 6개월간 완료한 운동을 저장했습니다.", type: "welcome")
            }
        }.store(in: &subscriptions)
    }
    
    @IBAction func sendEmail(_ sender: UIButton) {
        guard let email = emailField.text else { return }
        emailCheck.layer.isHidden = true
        view.endEditing(true) // 키보드 내리기
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
                        self.showAlert(title: "계정 사용 중지됨", description: "귀하의 계정이 사용 중지되었습니다. 문의사항은 관리자에게 해주세요.", type: "login")
                        return
                    }
                    print("Email Not Sent: \(error)")
                    configFirebase.errorReport(type: "LoginVC.sendEmail", descriptions: error.debugDescription)
                    self.showAlert(title: "인증 메일 발송 실패", description: "잠시 후 다시 시도해 주세요.", type: "login")
                } else {
                    print("Email Sent")
                    self.email = email
                    UserDefaults.standard.removeObject(forKey: "revoke") // 혹시 revoke 뷰로 가지 않게 하기위해 삭제
                    UserDefaults.standard.setValue(true, forKey: "login")
                    self.emailState.text = "인증 메일이 발송되었습니다. 본인 인증을 완료해 주세요."
                    self.emailState.textColor = .systemPink
                }
            }
        } else {
            showAlert(title: "인증 메일 발송 실패", description: "올바른 이메일 형식이 아닙니다.", type: "default")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension LoginViewController {
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
            case "login":
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
            }
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
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
