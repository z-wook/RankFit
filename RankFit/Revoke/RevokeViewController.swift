//
//  withdrawalViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/28.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

class RevokeViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailCheck: UIButton!
    @IBOutlet weak var emailState: UILabel!
    @IBOutlet weak var withdrawalBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    static let emailAuth = PassthroughSubject<String, Never>()
    var subscriptions = Set<AnyCancellable>()
    var cancel: Cancellable?
    let viewModel = RevokeViewModel()
    var email: String = saveUserData.getKeychainStringValue(forKey: .Email) ?? ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        bind()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cancel?.cancel()
    }
    
    private func configure() {
        emailField.placeholder = email
        emailField.isEnabled = false
        withdrawalBtn.layer.cornerRadius = 10
        withdrawalBtn.isHidden = true
        backgroundView.isHidden = true
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
    }
    
    private func bind() {
        let subject = RevokeViewController.emailAuth.receive(on: RunLoop.main).sink { link in
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            UserDefaults.standard.removeObject(forKey: "revoke")
            Auth.auth().signIn(withEmail: self.email, link: link) { result, error in
                if let error = error {
                    print("email auth error: \(error.localizedDescription) ")
                    configFirebase.errorReport(type: "RevokeVC.bind", descriptions: error.localizedDescription)
                    self.indicator.stopAnimating()
                    self.showAlert(title: "이메일 인증 실패", description: "이메일 인증에 실패하였습니다. 잠시 후 다시 시도해 주세요.")
                } else {
                    guard let result = result else {
                        configFirebase.errorReport(type: "RevokeVC.bind", descriptions: "result == nil")
                        self.indicator.stopAnimating()
                        self.showAlert(title: "탈퇴 실패", description: "잠시 후 다시 시도해 주세요.")
                        return
                    }
                    if result.user.email == saveUserData.getKeychainStringValue(forKey: .Email) {
                        self.backgroundView.isHidden = true
                        self.indicator.stopAnimating()
                        self.emailState.text = "이메일이 인증되었습니다."
                        self.emailState.textColor = .label
                        self.withdrawalBtn.isHidden = false
                    } else {
                        self.indicator.stopAnimating()
                        self.showAlert(title: "탈퇴 실패", description: "잠시 후 다시 시도해 주세요.")
                    }
                }
            }
        }
        cancel = subject
        
        viewModel.allClearSubject.receive(on: RunLoop.main).sink { result in
            if result {
                self.indicator.stopAnimating()
                self.withdrawalDoneAlert()
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "탈퇴 실패", description: "탈퇴 중 오류가 발생했습니다")
            }
        }.store(in: &subscriptions)
    }
    
    @IBAction func sendEmail(_ sender: UIButton) {
        guard let email = saveUserData.getKeychainStringValue(forKey: .Email) else {
            print("email 없음")
            return
        }
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: Store.shared.firebaseURL + "\(email)")
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendSignInLink(toEmail: email,
                                   actionCodeSettings: actionCodeSettings) { error in
            if let error = error {
                let error = error.localizedDescription
                if error == "The user account has been disabled by an administrator." {
                    self.showAlert(title: "계정 사용 중지됨", description: "귀하의 계정이 사용 중지되었습니다. 문의사항은 관리자에게 해주세요.")
                    return
                }
                print("Email Not Sent: \(error)")
                configFirebase.errorReport(type: "RevokeVC.sendEmail", descriptions: error)
                self.showAlert(title: "인증 메일 발송 실패", description: "잠시 후 다시 시도해 주세요.")
            } else {
                print("Email Sent")
                UserDefaults.standard.removeObject(forKey: "login") // 혹시 login 뷰로 가지 않게 하기위해 삭제
                UserDefaults.standard.setValue(true, forKey: "revoke")
                self.emailCheck.layer.isHidden = true
                self.emailState.text = "인증 메일이 발송되었습니다. 본인 인증을 완료해 주세요."
                self.emailState.textColor = .systemPink
            }
        }
    }
    
    @IBAction func withdrawalTapped(_ sender: UIButton) {
        withdrawalAlert()
    }
}

extension RevokeViewController {
    private func showAlert(title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func withdrawalAlert() {
        let alert = UIAlertController(title: "정말 탈퇴하시겠습니까?", message: "탈퇴하시면 사용자의 모든 정보가 삭제되고 복구할 수 없습니다.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "탈퇴하기", style: .destructive) { _ in
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            self.viewModel.initiateWithdrawal()
        }
        let cancel = UIAlertAction(title: "계정 유지", style: .default)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func withdrawalDoneAlert() {
        let alert = UIAlertController(title: "탈퇴 완료", message: "랭크핏을 종료합니다.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            // 자연스럽게 앱 종료하기
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exit(0) }
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}
