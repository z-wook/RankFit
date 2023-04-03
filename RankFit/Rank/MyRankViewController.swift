//
//  MyRankViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import FirebaseAuth
import Combine

class MyRankViewController: UIViewController {
    
    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let MyViewModel = MyRankViewModel()
    let OptionViewModel = OptionRankViewModel()
    static let profileSubject = PassthroughSubject<UIImage, Never>()
    let reporting = PassthroughSubject<String, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    var MyRankDatasource: UICollectionViewDiffableDataSource<Section, MyItem>!
    var OptionRankDatasource: UICollectionViewDiffableDataSource<Section, optionItem>!
    
    var myList: [[String: String]] = [] // 처음에 마이 랭킹 / 사용자가 완료한 운동 들어가야 함
    var user: User?
    var type: String = "마이랭킹"
    
    typealias MyItem = MyRankInfo
    typealias optionItem = OptionRankInfo
    enum Section {
        case my
        case option
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        updateNavigationItem()
        configureCollectionView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        user = Auth.auth().currentUser
        guard user != nil else {
            myList.removeAll()
            applyMyRankItems(items: [MyRankInfo(Exercise: "현재 로그아웃 되어\n랭킹을 불러들일 수 없습니다.", My_Ranking: "")])
            return
        }
        let sortlist = MyViewModel.getSortedExList() // 완료한 운동 get
        if type == "마이랭킹" && sortlist.isEmpty {
            myList.removeAll()
            indicator.stopAnimating()
            applyMyRankItems(items: [MyRankInfo(Exercise: "완료한 운동이 없습니다.", My_Ranking: "")])
            return
        }
        if type == "마이랭킹" && myList != sortlist {
            indicator.startAnimating()
            myList = sortlist
            MyViewModel.getMyRank()
        }
    }
    
    @IBAction func reporting(_ sender: UIButton) {
        reportUser(index: sender.tag)
    }
    
    private func bind() {
        MyViewModel.MySubject.receive(on: RunLoop.main).sink { rankList in
            // 마이랭킹 순위 받아오는 과정 중 다른 옵션을 선택했을 때 apply 하지 않도록 방지
            if self.type == "마이랭킹" && rankList?.isEmpty != true {
                self.indicator.stopAnimating()
                guard let rankList = rankList else {
                    self.applyMyRankItems(items: [MyRankInfo(Exercise: "서버 오류\n랭킹을 불러오는데 실패했습니다.\n다시 시도해 주세요.", My_Ranking: "")])
                    return
                }
                self.applyMyRankItems(items: rankList)
            }
        }.store(in: &subscriptions)
        
        OptionViewModel.optionSubject.receive(on: RunLoop.main).sink { rankList in
            if rankList?.isEmpty == true { return }
            self.indicator.stopAnimating()
            guard let rankList = rankList else {
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "서버 오류\n랭킹을 불러오는데 실패했습니다.\n다시 시도해 주세요.", My_Ranking: "")])
                return
            }
            self.applyOptionRankItems(items: rankList)
        }.store(in: &subscriptions)
        
        MyRankViewController.profileSubject.receive(on: RunLoop.main).sink { image in
            let sb = UIStoryboard(name: "Rank", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "ZoomProfileViewController") as! ZoomProfileViewController
            vc.image = image
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true)
        }.store(in: &subscriptions)
        
        reporting.receive(on: RunLoop.main).sink { result in
            switch result {
            case "done":
                self.showAlert(title: "신고 완료", message: "확인 후 빠르게 조치하겠습니다.")
                return
            case "already":
                self.showAlert(title: "신고 완료된 사용자", message: "이미 신고 처리된 사용자입니다.")
                return
            default: // fail
                self.showAlert(title: "신고 실패", message: "잠시 후 다시 시도해 주세요.")
                return
            }
        }.store(in: &subscriptions)
    }
}

extension MyRankViewController {
    private func configureCollectionView() {
        MyRankDatasource = UICollectionViewDiffableDataSource<Section, MyItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyRankCell", for: indexPath) as? MyRankCell else { return nil }
            cell.config(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout(type: 0)
        
        var MyRankSnapshot = NSDiffableDataSourceSnapshot<Section, MyItem>()
        MyRankSnapshot.appendSections([.my])
        MyRankSnapshot.appendItems([], toSection: .my)
        MyRankDatasource.apply(MyRankSnapshot)
    }
    
    private func layout(type: Int) -> UICollectionViewCompositionalLayout {
        var size: NSCollectionLayoutSize!
        switch type {
        case 0:
            let myRankSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            size = myRankSize
            
        default:
            var typeSize: CGFloat!
            // 뷰 전체 높이 길이
            let screenHeight = UIScreen.main.bounds.size.height
            if screenHeight == 568 { // 4 inch
                typeSize = 90
            } else if screenHeight <= 844 { // 6.1 inch
                typeSize = 110
            } else { // Over 6.1 inch
                typeSize = 120
            }
            let defaultSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(typeSize))
            size = defaultSize
        }
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applyMyRankItems(items: [MyRankInfo]) {
        indicator.stopAnimating()
        MyRankDatasource = UICollectionViewDiffableDataSource<Section, MyItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyRankCell", for: indexPath) as? MyRankCell else { return nil }
            cell.config(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout(type: 0)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, MyRankInfo>()
        snapshot.appendSections([.my])
        snapshot.appendItems(items, toSection: .my)
        MyRankDatasource.apply(snapshot)
    }
    
    private func applyOptionRankItems(items: [OptionRankInfo]) {
        OptionRankDatasource = UICollectionViewDiffableDataSource<Section, optionItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionCell", for: indexPath) as? OptionCell else { return nil }
            cell.configure(info: itemIdentifier)
            cell.reportBtn.tag = indexPath.item
            return cell
        })
        collectionView.collectionViewLayout = layout(type: 1)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, optionItem>()
        snapshot.appendSections([.option])
        snapshot.appendItems(items, toSection: .option)
        OptionRankDatasource.apply(snapshot)
    }
    
    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

extension MyRankViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch type {
        case "마이랭킹":
            let sb = UIStoryboard(name: "MyDetail", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "MyDetailViewController") as! MyDetailViewController
            if myList.count != 0 {
                let myList = MyViewModel.MySubject.value
                guard myList != nil else { return }
                vc.myInfo(exInfo: self.myList[indexPath.item])
                self.navigationController?.pushViewController(vc, animated: true)
            } else { return }
            
        default:
            if indexPath.item == 0 { return }
            let sb = UIStoryboard(name: "OptionDetail", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "OptionDetailViewController") as! OptionDetailViewController
            let optionList = OptionViewModel.optionSubject.value
            guard let optionList = optionList else { return }
            vc.userInfo(nickName: optionList[indexPath.item].Nickname)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension MyRankViewController {
    private func reportUser(index: Int) {
        let optionList = OptionViewModel.optionSubject.value
        guard let optionList = optionList else { return }
        let nickName = optionList[index].Nickname
        let alert = UIAlertController(title: "신고 사유 선택", message: nil, preferredStyle: .actionSheet)
        let reportProfile = UIAlertAction(title: "부적절한 프로필 사진", style: .default) { _ in
            configServer.reportUser(nickName: nickName, reason: 0, subject: self.reporting)
            configFirebase.userReport(nickName: nickName, reason: 0)
        }
        let reportNickName = UIAlertAction(title: "부적절한 닉네임", style: .default) { _ in
            configServer.reportUser(nickName: nickName, reason: 1, subject: self.reporting)
            configFirebase.userReport(nickName: nickName, reason: 1)
        }
        let reportScore = UIAlertAction(title: "랭킹 오류 / 랭킹 악용 의심", style: .default) { _ in
            configServer.reportUser(nickName: nickName, reason: 2, subject: self.reporting)
            configFirebase.userReport(nickName: nickName, reason: 2)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(reportProfile)
        alert.addAction(reportNickName)
        alert.addAction(reportScore)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    private func configure() {
        optionButton.tintColor = UIColor(named: "link_cyan")
        collectionView.delegate = self
        let screenHeight = UIScreen.main.bounds.size.height
        if screenHeight == 568 { // for iPhone SE1
            optionButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        }
    }
    
    private func updateNavigationItem() {
        let scoreConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "questionmark.circle"),
            color: UIColor(named: "link_cyan"),
            handler: {
                let sb = UIStoryboard(name: "Reading", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "defaultViewController") as! defaultViewController
                vc.configure(type: "랭킹")
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }
        )
        let scoreItem = UIBarButtonItem.generate(with: scoreConfig, width: 30)
        navigationItem.leftBarButtonItem = scoreItem
        
        let me = UIAction(title: "마이랭킹", handler: { _ in
            if self.type == "마이랭킹" { return }
            self.navigationItem.title = "주간 랭킹"
            self.type = "마이랭킹"
            self.optionButton.setTitle("마이랭킹", for: .normal)
            self.applyMyRankItems(items: [])
            guard self.user != nil else {
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "현재 로그아웃 되어\n랭킹을 불러들일 수 없습니다.", My_Ranking: "")])
                return
            }
            self.indicator.startAnimating()
            let sortlist = self.MyViewModel.getSortedExList() // 완료한 운동 get
            self.myList = sortlist
            if sortlist.count == 0 {
                self.indicator.stopAnimating()
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "완료한 운동이 없습니다.", My_Ranking: "")])
                return
            }
            self.MyViewModel.getMyRank()
        })
        
        let gender = UIAction(title: "성별", handler: { _ in
            if self.type == "성별" { return }
            self.navigationItem.title = "주간 성별 랭킹"
            self.type = "성별"
            self.optionButton.setTitle("성별", for: .normal)
            self.applyOptionRankItems(items: [])
            guard self.user != nil else {
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "현재 로그아웃 되어\n랭킹을 불러들일 수 없습니다.", My_Ranking: "")])
                return
            }
            self.indicator.startAnimating()
            self.OptionViewModel.getGenderRank()
        })
        
        let age = UIAction(title: "나이", handler: { _ in
            if self.type == "나이" { return }
            self.navigationItem.title = "주간 나이 랭킹"
            self.type = "나이"
            self.optionButton.setTitle("나이", for: .normal)
            self.applyOptionRankItems(items: [])
            guard self.user != nil else {
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "현재 로그아웃 되어\n랭킹을 불러들일 수 없습니다.", My_Ranking: "")])
                return
            }
            self.indicator.startAnimating()
            self.OptionViewModel.getAgeRank()
        })
        
        let all = UIAction(title: "종합", handler: { _ in
            if self.type == "종합" { return }
            self.navigationItem.title = "주간 종합 랭킹"
            self.type = "종합"
            self.optionButton.setTitle("종합", for: .normal)
            self.applyOptionRankItems(items: [])
            guard self.user != nil else {
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "현재 로그아웃 되어\n랭킹을 불러들일 수 없습니다.", My_Ranking: "")])
                return
            }
            self.indicator.startAnimating()
            self.OptionViewModel.getCustomRank()
        })
        
        let running = UIAction(title: "러닝", handler: { _ in
            if self.type == "러닝" { return }
            self.navigationItem.title = "주간 러닝 랭킹"
            self.type = "러닝"
            self.optionButton.setTitle("러닝", for: .normal)
            self.applyOptionRankItems(items: [])
            guard self.user != nil else {
                self.applyMyRankItems(items: [MyRankInfo(Exercise: "현재 로그아웃 되어\n랭킹을 불러들일 수 없습니다.", My_Ranking: "")])
                return
            }
            self.indicator.startAnimating()
            self.OptionViewModel.getRunningRank()
        })
        
        let buttonMenu = UIMenu(title: "옵션", children: [me, gender, age, all, running])
        optionButton.menu = buttonMenu
        optionButton.showsMenuAsPrimaryAction = true
        optionButton.changesSelectionAsPrimaryAction = true
        optionButton.fs_width = 100
        
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = UIColor(named: "link_cyan")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "주간 랭킹"
    }
}
