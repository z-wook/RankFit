//
//  SettingViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine
import FirebaseAuth

class SettingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    static var reloadProfile = PassthroughSubject<Bool, Never>()
    let logoutState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    let sectionHeader = ["내 프로필", "앱 설정", "이용 안내", "기타"]
    let section0 = ["마이페이지"] // userInfomation
    let section1 = ["다크모드", "기타 등등"]
    let section2 = ["버전 정보", "개인 정보 취급 방침", "이용약관", "공지사항", "문의하기"]
    let section3 = ["로그아웃"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        updateNavigationItem()
        bind()
    }
    
    private func bind() {
        SettingViewController.reloadProfile.receive(on: RunLoop.main).sink { _ in
            print("Setting Reload")
            self.tableView.reloadData()
        }.store(in: &subscriptions)
        
        logoutState.receive(on: RunLoop.main).sink { _ in
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
                // 프로필 업데이트
                self.tableView.reloadData()
            } catch {
                print("error: " + error.localizedDescription)
                configFirebase.errorReport(type: "SettingVC.bind", descriptions: error.localizedDescription)
                self.showAlert(title: "로그아웃 실패", description: "잠시 후 다시 시도해 주세요.")
            }
        }.store(in: &subscriptions)
    }
}

extension SettingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeader.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeader[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0.count
        case 1: return section1.count
        case 2: return section2.count
        case 3: return section3.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 120.0
        default: return 50.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let profileCell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
                return UITableViewCell()
            }
            profileCell.configCell()
            return profileCell
            
        case 1:
            guard let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? DefaultCell else {
                return UITableViewCell()
            }
            defaultCell.imgView.image = UIImage(systemName: "lightbulb.fill")
//            defaultCell.imgView.image?.withRenderingMode(.alwaysOriginal)
            defaultCell.title.text = section1[indexPath.row]
            
            return defaultCell
            
        case 2:
            guard let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? DefaultCell else {
                return UITableViewCell()
            }
            defaultCell.title.text = section2[indexPath.row]
            return defaultCell
            
        case 3:
            guard let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? DefaultCell else {
                return UITableViewCell()
            }
            defaultCell.title.text = section3[indexPath.row]
            return defaultCell
            
        default:
            return UITableViewCell()
        }
    }
}

extension SettingViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if checkRegister().isNewUser() { // 회원가입 창 방문 전
                let sb = UIStoryboard(name: "Register", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "ChoiceWayViewController") as! ChoiceWayViewController
                navigationController?.pushViewController(vc, animated: true)
            } else {
                let user = Auth.auth().currentUser
                if user != nil { // 로그인 된 상태 -> 프로필 창으로
                    let sb = UIStoryboard(name: "MyProfile", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "MyProfileViewController") as! MyProfileViewController
                    navigationController?.pushViewController(vc, animated: true)
                } else { // 로그아웃 상태 -> 로그인 창으로
                    let sb = UIStoryboard(name: "Login", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
            
        case 1:
            return
            
        case 2:
            if indexPath.item == 3 { // 공지사항
                let sb = UIStoryboard(name: "Notice", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "NoticeViewController") as! NoticeViewController
                navigationController?.pushViewController(vc, animated: true)
            }
            
        case 3:
            let user = Auth.auth().currentUser
            if user != nil { // 로그인 된 상태
                showLogOutConfirmAlert()
            } else {
                showAlert(title: "로그아웃", description: "이미 로그아웃 된 상태입니다.")
            }
            
        default:
            return
        }
    }
    
    private func showAlert(title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showLogOutConfirmAlert() {
        let alert = UIAlertController(title: "로그아웃하시겠습니까?", message: "로그아웃하시면 랭크핏 서비스를 이용할 수 없습니다.", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "로그인 유지", style: .default)
        let ok = UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            self.logoutState.send(true)
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
}

extension SettingViewController {
    private func updateNavigationItem() {
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.title = "설정"
    }
}

class checkRegister {
    static let shared = checkRegister()
    
    func isNewUser() -> Bool {
        return !UserDefaults.standard.bool(forKey: "checkRegister")
    }
    
    func setIsNotNewUser() {
        UserDefaults.standard.set(true, forKey: "checkRegister")
    }
}
