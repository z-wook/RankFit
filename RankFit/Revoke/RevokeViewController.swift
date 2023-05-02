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
    
    let subject = PassthroughSubject<String, Never>()
    var subscriptions = Set<AnyCancellable>()
    let viewModel = RevokeViewModel()
    var center: NotificationCenter?
    var email: String = saveUserData.getKeychainStringValue(forKey: .Email) ?? ""
    enum Error: String {
        case expired = "The action code is invalid. This can happen if the code is malformed, expired, or has already been used."
        case denied = "The user account has been disabled by an administrator."
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        bind()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        center?.removeObserver(self)
        subscriptions.removeAll()
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
        subject.receive(on: RunLoop.main).sink { link in
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            UserDefaults.standard.removeObject(forKey: "revoke")
            Auth.auth().signIn(withEmail: self.email, link: link) { result, error in
                if let error = error {
                    self.indicator.stopAnimating()
                    let error = error.localizedDescription
                    if error == Error.expired.rawValue {
                        print("만료된 이메일 인증 링크")
                        self.showAlert(title: "이메일 인증 실패", description: "만료된 이메일 인증 링크입니다. 잠시 후 다시 시도해 주세요.")
                        return
                    } else {
                        print("email auth error: \(error)")
                        configFirebase.errorReport(type: "RevokeVC.bind", descriptions: error)
                        self.showAlert(title: "이메일 인증 실패", description: "이메일 인증에 실패하였습니다. 잠시 후 다시 시도해 주세요.")
                        return
                    }
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
        }.store(in: &subscriptions)
        
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
        view.endEditing(true) // 키보드 내리기
        center?.removeObserver(self)
        guard let email = saveUserData.getKeychainStringValue(forKey: .Email) else {
            return print("email 없음")
        }
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: Store.shared.firebaseURL + "\(email)")
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendSignInLink(toEmail: email,
                                   actionCodeSettings: actionCodeSettings) { error in
            if let error = error {
                let error = error.localizedDescription
                if error == Error.denied.rawValue {
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
                // Notification 생성
                self.center = NotificationCenter.default
                self.center?.addObserver(self, selector: #selector(self.Revoke), name: NSNotification.Name("revoke"), object: nil)
            }
        }
    }
    
    @IBAction func withdrawalTapped(_ sender: UIButton) {
        withdrawalAlert()
    }
}

extension RevokeViewController {
    @objc func Revoke(notification: NSNotification) {
        guard let link = notification.userInfo?["link"] as? String else {
            showAlert(title: "이메일 인증 실패", description: "이메일 인증에 실패하였습니다. 잠시 후 다시 시도해 주세요.")
            return
        }
        subject.send(link)
    }
    
    private func showAlert(title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.center?.removeObserver(self)
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
        let cancel = UIAlertAction(title: "계정 유지", style: .default) { _ in
            self.center?.removeObserver(self)
            self.navigationController?.popViewController(animated: true)
        }
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
