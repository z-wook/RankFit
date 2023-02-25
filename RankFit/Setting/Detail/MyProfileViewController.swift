//
//  MyProfileViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/16.
//

import UIKit
import Combine

class MyProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let sectionHeader = ["내 정보", "계정"]
    let section0 = ["이메일", "성별", "나이", "몸무게", "닉네임", "프로필"]
    let section1 = ["서비스 탈퇴"]
    
    let user = getSavedDateInfo()
    var userInfomation: [Any] = [] // ["성별", "나이", "몸무게", "닉네임", "프로필"]
    static var userWeight = PassthroughSubject<Int, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNavigationItem()
        configure()
        bind()
    }
    
    func bind() {
        MyProfileViewController.userWeight.receive(on: RunLoop.main)
            .sink { infoWeight in
                self.userInfomation[3] = infoWeight
                self.tableView.reloadData()
            }.store(in: &subscriptions)
    }
}

extension MyProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0.count
        case 1: return section1.count
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
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyProfileCell", for: indexPath) as? MyProfileCell else {
                return UITableViewCell()
            }
            cell.configCell(title: section0[indexPath.item], infomation: "\(userInfomation[indexPath.item])")
            if indexPath.item >= 3 && indexPath.item <= 5 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyProfileCell", for: indexPath) as? MyProfileCell else {
                return UITableViewCell()
            }
            cell.configCell(title: section1[indexPath.item], infomation: "none")
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
            
        case 1: // 서비스 탈퇴
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
        
        userInfomation = [email, gender, age, weight, nickname, profile]
    }
}
