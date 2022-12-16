//
//  SettingViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit

class SettingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
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
        case 0: return 100.0
        default: return 50.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            guard let profileCell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
                return UITableViewCell()
            }
//            profileCell.profileImage =
            profileCell.nickName.text = "정보없음"
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
            let sb = UIStoryboard(name: "MyProfile", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "MyProfileViewController") as! MyProfileViewController
            
            self.navigationController?.pushViewController(vc, animated: true)
            
            
        case 1:
            
            return
            
        default:
            return
        }
        
        
        
    }
}

extension SettingViewController {
    private func updateNavigationItem() {
//        let titleConfig = CustomBarItemConfiguration(
//            title: "운동",
//            handler: { }
//        )
//        let titleItem = UIBarButtonItem.generate(with: titleConfig)
//
//        let feedConfig = CustomBarItemConfiguration(
//            image: UIImage(systemName: "plus"),
//            handler: {
//                let sb = UIStoryboard(name: "ExerciseList", bundle: nil)
//                let vc = sb.instantiateViewController(withIdentifier: "ExerciseListViewController") as! ExerciseListViewController
//                vc.viewModel = ExerciseListViewModel(items: ExerciseInfo.sortedList)
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        )
//        let feedItem = UIBarButtonItem.generate(with: feedConfig, width: 30)
//
//        navigationItem.leftBarButtonItem = titleItem
//        navigationItem.rightBarButtonItems = [feedItem]
//        navigationItem.title = "운동"
        
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationItem.backButtonDisplayMode = .minimal
        
        // backBarButtonTitle 설정
//        let backBarButtonItem = UIBarButtonItem(title: "이전 페이지", style: .plain, target: self, action: nil)
//        navigationItem.backBarButtonItem = backBarButtonItem
    }
}
