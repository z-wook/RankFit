//
//  SettingViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine
import FirebaseAuth
import SafariServices

class SettingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    static var reloadProfile = PassthroughSubject<Bool, Never>()
    let logoutState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    let sectionHeader = ["내 프로필", "앱 설정", "이용 안내", "기타"]
    let section0 = ["마이페이지"] // userInformation
    let section1 = ["화면 모드", "사운드 효과", "알림 설정"]
    let section2 = ["버전 정보", "개인정보 처리 방침", "오픈소스 라이선스", "이용약관", "이용규칙", "공지사항", "문의하기"]
    let section3 = ["개발진", "저작권", "로그아웃"]
    let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" // 버전 정보
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        updateNavigationItem()
        bind()
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
        case 0:
            // 뷰 전체 높이
            let screenHeight = UIScreen.main.bounds.size.height
            if screenHeight == 568 { // 4 inch
                return 100.0
            } else {
                return 120.0
            }
            
        default: return 50.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let profileCell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else { return UITableViewCell() }
            profileCell.configCell()
            return profileCell
            
        case 1:
            guard let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? DefaultCell else { return UITableViewCell() }
            var img: UIImage?
            var color: UIColor?
            var mode: String?
            if indexPath.item == 0 { // 화면 모드
                img = UIImage(systemName: "lightbulb")
                color = .systemOrange
                let rawValue = UserDefaults.standard.integer(forKey: "Appearance")
                switch rawValue {
                case 1: mode = "라이트 모드"
                case 2: mode = "다크 모드"
                default: mode = "시스템 기본값"
                }
            } else if indexPath.item == 1 { // 사운드 효과
                img = UIImage(systemName: "speaker.wave.3")
                color = .link
                let soundEffect = UserDefaults.standard.integer(forKey: "sound")
                if soundEffect == 0 { mode = "On" }
                else { mode = "Off" }
            } else { // 알림 설정
                img = UIImage(systemName: "exclamationmark.bubble")
                color = .systemPink
            }
            defaultCell.configure(image: img, color: color, title: section1[indexPath.row], description: mode)
            return defaultCell
            
        case 2:
            guard let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? DefaultCell else { return UITableViewCell() }
            var img: UIImage?
            var color: UIColor?
            if indexPath.item == 0 { // 버전 정보
                img = UIImage(systemName: "app.badge")
            } else if indexPath.item == 1 { // 개인정보 처리 방침
                img = UIImage(systemName: "checkmark.shield")
                color = .systemBrown
            } else if indexPath.item == 2 { // 오픈소스 라이선스
                img = UIImage(systemName: "doc")
                color = .systemGreen
            } else if indexPath.item == 5 { // 공지사항
                img = UIImage(systemName: "megaphone")
                color = .systemYellow
            } else if indexPath.item == 6 { // 문의하기
                img = UIImage(systemName: "text.bubble")
                color = .systemCyan
            } else { // 이용약관, 이용규칙
                img = UIImage(systemName: "newspaper")
                color = UIColor(named: "darkTxt_lightTxt")
            }
            defaultCell.configure(image: img, color: color, title: section2[indexPath.row])
            return defaultCell
            
        case 3:
            guard let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as? DefaultCell else { return UITableViewCell() }
            var img: UIImage?
            var color: UIColor?
            if indexPath.item == 0 { // 개발진
                img = UIImage(systemName: "person.2.circle.fill")
                color = .label
            } else if indexPath.item == 1 { // 저작권
                img = UIImage(systemName: "square.and.pencil")
                color = UIColor(named: "darkTxt_lightTxt")
            } else { // 로그아웃
                img = UIImage(systemName: "person.fill.xmark")
                color = .label
            }
            defaultCell.configure(image: img, color: color, title: section3[indexPath.row])
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
                return
            } else {
                let user = Auth.auth().currentUser
                if user != nil { // 로그인 된 상태 -> 프로필 창으로
                    let sb = UIStoryboard(name: "MyProfile", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "MyProfileViewController") as! MyProfileViewController
                    navigationController?.pushViewController(vc, animated: true)
                } else { // 로그아웃 상태 -> 로그인 창으로
                    // 이메일 인증 or 비밀번호 인증 선택하기
                    showLoginType()
                }
            }
            
        case 1:
            if indexPath.item == 0 {
                let alert = UIAlertController(title: "화면 모드", message: nil, preferredStyle: .actionSheet)
                // unspecified = 0, light = 1, dark = 2
                let system = UIAlertAction(title: "시스템 기본값", style: .default) { _ in
                    UserDefaults.standard.set(0, forKey: "Appearance")
                    self.view.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: 0) ?? .unspecified
                    tableView.reloadData()
                }
                let light = UIAlertAction(title: "라이트 모드", style: .default) { _ in
                    UserDefaults.standard.set(1, forKey: "Appearance")
                    self.view.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: 1) ?? .unspecified
                    tableView.reloadData()
                }
                let dark = UIAlertAction(title: "다크 모드", style: .default) { _ in
                    UserDefaults.standard.set(2, forKey: "Appearance")
                    self.view.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: 2) ?? .unspecified
                    tableView.reloadData()
                }
                let cancel = UIAlertAction(title: "취소", style: .cancel)
                alert.addAction(system)
                alert.addAction(light)
                alert.addAction(dark)
                alert.addAction(cancel)
                present(alert, animated: true)
            } else if indexPath.item == 1 {
                let alert = UIAlertController(title: "사운드 효과", message: nil, preferredStyle: .actionSheet)
                let on = UIAlertAction(title: "On", style: .default) { _ in
                    UserDefaults.standard.set(0, forKey: "sound")
                    tableView.reloadData()
                }
                let off = UIAlertAction(title: "Off", style: .default) { _ in
                    UserDefaults.standard.set(1, forKey: "sound")
                    tableView.reloadData()
                }
                let cancel = UIAlertAction(title: "취소", style: .cancel)
                alert.addAction(on)
                alert.addAction(off)
                alert.addAction(cancel)
                present(alert, animated: true)
            } else { // 알림 설정
                // 설정으로 이동
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            
        case 2:
            if indexPath.item == 0 { // 버전 정보
                let sb = UIStoryboard(name: "Version", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "VersionViewController") as! VersionViewController
                vc.version = version
                navigationController?.pushViewController(vc, animated: true)
                return
            } else if indexPath.item == 1 { // 개인정보 처리 방침
                let url = URL(string: "https://plip.kr/pcc/7f8b391c-e3e7-4847-8218-4ec213087f4c/privacy/2.html")
                let vc = SFSafariViewController(url: url!)
                present(vc, animated: true)
                return
            } else if indexPath.item == 2 { // 오픈소스 라이선스
                // 설정으로 이동
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                return
            } else if indexPath.item == 3 { // 이용약관
                let sb = UIStoryboard(name: "Reading", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "defaultViewController") as! defaultViewController
                vc.configure(type: "이용약관")
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
                return
            } else if indexPath.item == 4 { // 이용규칙
                let sb = UIStoryboard(name: "Reading", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "defaultViewController") as! defaultViewController
                vc.configure(type: "이용규칙")
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
                return
            } else if indexPath.item == 5 { // 공지사항
                let sb = UIStoryboard(name: "Notice", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "NoticeViewController") as! NoticeViewController
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
                return
            } else { // 문의하기
                let sb = UIStoryboard(name: "Ask", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "AskViewController") as! AskViewController
                vc.navigationItem.largeTitleDisplayMode = .always
                navigationController?.pushViewController(vc, animated: true)
            }
            
        case 3:
            if indexPath.item == 0 { // 개발진
                let sb = UIStoryboard(name: "Reading", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "defaultViewController") as! defaultViewController
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.configure(type: "개발진")
                navigationController?.pushViewController(vc, animated: true)
                return
            } else if indexPath.item == 1 { // 저작권
                let sb = UIStoryboard(name: "Reading", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "defaultViewController") as! defaultViewController
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.configure(type: "저작권")
                navigationController?.pushViewController(vc, animated: true)
                return
            } else { // 로그아웃
                let user = Auth.auth().currentUser
                if user != nil { // 로그인 된 상태
                    showLogOutConfirmAlert()
                    return
                } else {
                    showAlert(title: "로그아웃", description: "이미 로그아웃 된 상태입니다.")
                }
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
    
    private func showLoginType() {
        let sb = UIStoryboard(name: "Login", bundle: nil)
        let alert = UIAlertController(title: "로그인 인증 선택", message: nil, preferredStyle: .alert)
        let email = UIAlertAction(title: "이메일 인증 로그인", style: .default) { _ in
            let vc = sb.instantiateViewController(withIdentifier: "EmailLoginViewController") as! EmailLoginViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let password = UIAlertAction(title: "비밀번호 인증 로그인", style: .default) { _ in
            let vc = sb.instantiateViewController(withIdentifier: "PasswordLoginViewController") as! PasswordLoginViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let cancel = UIAlertAction(title: "취소", style: .destructive)
        alert.addAction(email)
        alert.addAction(password)
        alert.addAction(cancel)
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
        navigationController?.navigationBar.tintColor = UIColor(named: "link_cyan")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.title = "설정"
    }
    
    private func bind() {
        SettingViewController.reloadProfile.receive(on: RunLoop.main).sink { _ in
            print("Setting Reload")
            // auth reload
            Auth.auth().currentUser?.reload(completion: { error in
                if let error = error {
                    let error = error.localizedDescription
                    print("error: \(error)")
                    // 1. "The user account has been disabled by an administrator."
                    // 2. "The user's credential is no longer valid. The user must sign in again."
                    self.logoutState.send(true)
                    return
                }
            })
            let user = Auth.auth().currentUser
            if user != nil { // 로그인 된 상태 -> 프로필 창으로
                self.tableView.reloadData()
                return
            } else { // 로그아웃 상태 -> 로그인 창으로
                print("로그아웃 상태")
                self.logoutState.send(true)
            }
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
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "SettingVC.bind", descriptions: error.localizedDescription)
                self.showAlert(title: "로그아웃 실패", description: "잠시 후 다시 시도해 주세요.")
            }
        }.store(in: &subscriptions)
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
