//
//  MyProfileViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/16.
//

import UIKit

class MyProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let sectionHeader = ["내 정보", "계정"]
    let section0 = ["이메일", "성별", "닉네임", "나이", "몸무게"]
    let section1 = ["서비스 탈퇴"]
    
    
    let user = getUserInfo()
    
    
    var userInfomation: [Any] = [] // [이메일, 성별, 닉네임, 나이, 몸무게]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.backButtonDisplayMode = .minimal
        
        
        userInfomation = [user.getEmail(), user.getGender(),
                          user.getNickName(), user.getAge(), user.getWeight()]
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
            if indexPath.item >= 2 && indexPath.item <= 4 {
                cell.accessoryType = .disclosureIndicator
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
            if indexPath.item == 1 {
                // 닉네임
                
                
                
                
            }
            // 나이, 몸무게
            else if (indexPath.item == 3 || indexPath.item == 4) {
                let sb = UIStoryboard(name: "InputInfo", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "InputInfoViewController") as! InputInfoViewController
                vc.configure(type: section0[indexPath.item])
                self.navigationController?.pushViewController(vc, animated: true)
                
                
                
                
            } else {
                return
            }
            
        case 1:
            // 서비스 탈퇴
            return
            
        default: return
        }
    }
    
}
