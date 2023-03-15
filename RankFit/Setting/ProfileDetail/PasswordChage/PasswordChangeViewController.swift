//
//  PasswordChangeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/14.
//

import UIKit
import FirebaseAuth

class PasswordChangeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "비밀번호 재설정"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SettingViewController.reloadProfile.send(true)
    }
    
    @IBAction func sendEmail(_ sender: UIButton) {
        // 비밀번호 재설정 이메일 보내기
        let email = saveUserData.getKeychainStringValue(forKey: .Email)
        guard let email = email else {
            self.showAlert(title: "비밀번호 재설정 오류", message: "현재 이메일 정보가 없습니다.")
            return
        }
        confirmAlert(email: email)
    }
    
    private func confirmAlert(email: String) {
        let alert = UIAlertController(title: "비밀번호 재설정 확인", message: "비밀번호를 재설정하시겠습니까? 동의하시면 비밀번호 변경 이메일이 전송됩니다.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "동의", style: .default) { _ in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print("error: \(error.localizedDescription)")
                    configFirebase.errorReport(type: "MyProfileVC.didSelectRowAt", descriptions: error.localizedDescription)
                    self.showAlert(title: "비밀번호 재설정 오류", message: "잠시 후 다시 시도해 주세요.")
                } else {
                    print("이메일 전송 성공")
                    do {
                        try Auth.auth().signOut()
                        print("로그아웃 성공")
                        // 저장된 개인 정보 삭제
                        saveUserData.removeKeychain(forKey: .Email)
                        saveUserData.removeKeychain(forKey: .UID)
                        saveUserData.removeKeychain(forKey: .NickName)
                        saveUserData.removeKeychain(forKey: .Gender)
                        saveUserData.removeKeychain(forKey: .Birth)
                        saveUserData.removeKeychain(forKey: .Weight)
                    } catch {
                        print("error: \(error.localizedDescription)")
                        configFirebase.errorReport(type: "PasswordChangeVC.confirmAlert", descriptions: error.localizedDescription)
                    }
                    self.showAlert(title: "이메일 전송 완료", message: "비밀번호 재설정을 위해 이메일을 전송했습니다. 이메일을 통해 비밀번호 재설정 후 다시 로그인해 주세요.")
                }
            }
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
}
