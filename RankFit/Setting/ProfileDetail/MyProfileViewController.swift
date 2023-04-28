//
//  MyProfileViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/16.
//

import UIKit

class MyProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let sectionHeader = ["내 정보", "계정", "서비스"]
    let section0 = ["이메일", "성별", "나이", "몸무게", "닉네임", "프로필"]
    let section1 = ["비밀번호 재설정"]
    let section2 = ["서비스 탈퇴"]
    
    let user = getSavedDateInfo()
    var userInformation: [Any] = [] // ["성별", "나이", "몸무게", "닉네임", "프로필"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNavigationItem()
        configure()
    }
}

extension MyProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0.count
        case 1: return section1.count
        case 2: return section2.count
        default: return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeader.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeader[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyProfileCell", for: indexPath) as? MyProfileCell else {
            return UITableViewCell()
        }
        switch indexPath.section {
        case 0:
            cell.configCell(title: section0[indexPath.item], information: "\(userInformation[indexPath.item])")
            if indexPath.item >= 3 && indexPath.item <= 5 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
            return cell
            
        case 1:
            cell.configCell(title: section1[indexPath.item], information: "none")
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case 2:
            cell.configCell(title: section2[indexPath.item], information: "none")
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if section0[indexPath.item] == "몸무게" {
                let sb = UIStoryboard(name: "InputInfo", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "ChangeWeightViewController") as! ChangeWeightViewController
                self.navigationController?.pushViewController(vc, animated: true)
            } else if section0[indexPath.item] == "닉네임" {
                let sb = UIStoryboard(name: "InputInfo", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "ChangeNickNameViewController") as! ChangeNickNameViewController
                self.navigationController?.pushViewController(vc, animated: true)
            } else if section0[indexPath.item] == "프로필" {
                let sb = UIStoryboard(name: "InputInfo", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "ChangeProfileViewController") as! ChangeProfileViewController
                self.navigationController?.pushViewController(vc, animated: true)
            } else { return }
            
        case 1: // 비밀번호 재설정
            let sb = UIStoryboard(name: "PasswordChange", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "PasswordChangeViewController") as! PasswordChangeViewController
            self.navigationController?.pushViewController(vc, animated: true)
            
        case 2: // 서비스 탈퇴
            let sb = UIStoryboard(name: "Revoke", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "RevokeViewController") as! RevokeViewController
            self.navigationController?.pushViewController(vc, animated: true)
            
        default: return
        }
    }
}

extension MyProfileViewController {
    private func updateNavigationItem() {
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "내 정보"
    }
    
    private func configure() {
        tableView.dataSource = self
        tableView.delegate = self
        
        let email = saveUserData.getKeychainStringValue(forKey: .Email) ?? "정보 없음"
        let gender = saveUserData.getKeychainIntValue(forKey: .Gender) ?? 0
        let nickname = saveUserData.getKeychainStringValue(forKey: .NickName) ?? "정보 없음"
        let birth = saveUserData.getKeychainStringValue(forKey: .Birth)
        let age = calcDate().getAge(BDay: birth!)
        let weight = saveUserData.getKeychainIntValue(forKey: .Weight) ?? 1
        let profile = "blank_profile"

        userInformation = [email, gender, age, weight, nickname, profile]
    }
}

extension MyProfileViewController {
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
}
