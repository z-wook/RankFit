//
//  MyRankViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine

class MyRankViewController: UIViewController {

    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let MyViewModel = MyRankViewModel()
    let OptionViewModel = OptionRankViewModel()
    
    var MyRankDatasource: UICollectionViewDiffableDataSource<Section, Item>!
    var OptionRankDatasource: UICollectionViewDiffableDataSource<Section, optionItem>!
    
    var list: [String] = [] // 처음에 마이 랭킹 / 사용자가 완료한 운동 들어가야 함
    var type: String = "마이랭킹"
    
    let myExercise = PassthroughSubject<[String], Never>()
    var subscriptions = Set<AnyCancellable>()
    
    typealias Item = String
    typealias optionItem = receiveRankInfo
    enum Section {
        case main
        case option
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        updateNavigationItem()
        configureCollectionView()
        bind()
        
        let sortlist = MyViewModel.getSortedExList() // 완료한 운동 get
        list = sortlist
        myExercise.send(sortlist) // 완료 운동 전송
    }
    
    private func bind() {
        myExercise.receive(on: RunLoop.main)
            .sink { exList in
                self.applyMyRankItems(items: exList)
            }.store(in: &subscriptions)
        
        OptionViewModel.optionSubject.receive(on: RunLoop.main)
            .sink { rankList in
                self.applyOptionRankItems(items: rankList)
            }.store(in: &subscriptions)
    }
}

extension MyRankViewController {
    private func configureCollectionView() {
        MyRankDatasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyRankCell", for: indexPath) as? MyRankCell else { return nil }
            cell.config(info: itemIdentifier)
            return cell
        })

        collectionView.collectionViewLayout = layout(type: 0)

        var MyRankSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        MyRankSnapshot.appendSections([.main])
        MyRankSnapshot.appendItems([], toSection: .main)
        MyRankDatasource.apply(MyRankSnapshot)
        
//        OptionRankDatasource = UICollectionViewDiffableDataSource<Section, optionItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
//            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionCell", for: indexPath) as? OptionCell else { return nil }
//            cell.config(info: itemIdentifier)
//            return cell
//        })
        
//        collectionView.collectionViewLayout = layout()
        
//        var OptionRankSnapshot = NSDiffableDataSourceSnapshot<Section, optionItem>()
//        OptionRankSnapshot.appendSections([.option])
//        OptionRankSnapshot.appendItems([], toSection: .option)
//        OptionRankDatasource.apply(OptionRankSnapshot)
    }
    
    private func layout(type: Int) -> UICollectionViewCompositionalLayout {
        var size: NSCollectionLayoutSize!
        
        switch type {
        case 0:
            let myRankSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(60))
            size = myRankSize
            
        case 1:
            let optionRankSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            size = optionRankSize
            
        default:
            let defaultSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(60))
            size = defaultSize
        }
        
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applyMyRankItems(items: [String]) {
        MyRankDatasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyRankCell", for: indexPath) as? MyRankCell else { return nil }
            cell.config(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout(type: 0)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        MyRankDatasource.apply(snapshot)
    }
    
    private func applyOptionRankItems(items: [receiveRankInfo]) {
        OptionRankDatasource = UICollectionViewDiffableDataSource<Section, optionItem>(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionCell", for: indexPath) as? OptionCell else { return nil }
            cell.config(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout(type: 1)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, optionItem>()
        snapshot.appendSections([.option])
        snapshot.appendItems(items, toSection: .option)
        OptionRankDatasource.apply(snapshot)
    }
}

extension MyRankViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("click: \(indexPath.item)")
        
        switch type {
        case "마이랭킹":
            
            let sb = UIStoryboard(name: "MyDetail", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "MyDetailViewController") as! MyDetailViewController
            
            if list.count != 0 {
                vc.myInfo(title: list[indexPath.item], rank: "3위", score: "142점")
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                return print("완료한 운동이 없습니다.")
            }
            
            
            return
            
        case "성별":
            
            let sb = UIStoryboard(name: "OptionRank", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "OptionRankViewController") as! OptionRankViewController
            self.navigationController?.pushViewController(vc, animated: true)
            
            
            return
            
            
            
        case "나이":
            
            return
            
        case "맞춤(종합)":
            
            return
            
        default:
            return
        }
    }
}








extension MyRankViewController {
    private func updateNavigationItem() {
        // Pull Down Button
        let me = UIAction(title: "마이랭킹", handler: { _ in
            if self.type == "마이랭킹" { return }
            self.navigationItem.title = "주간 랭킹"
            self.type = "마이랭킹"
            self.optionButton.setTitle("마이랭킹", for: .normal)
            let sortlist = self.MyViewModel.getSortedExList() // 완료한 운동 get
            self.list = sortlist
            self.myExercise.send(sortlist) // 완료 운동 전송
        })
        
        let gender = UIAction(title: "성별", handler: { _ in
            if self.type == "성별" { return }
            self.navigationItem.title = "주간 성별 랭킹"
            self.type = "성별"
            self.optionButton.setTitle("성별", for: .normal)
            self.OptionViewModel.getGenderRank()
        })
        
        let age = UIAction(title: "나이", handler: { _ in
            if self.type == "나이" { return }
            self.navigationItem.title = "주간 나이 랭킹"
            self.type = "나이"
            self.optionButton.setTitle("나이", for: .normal)
            self.OptionViewModel.getAgeRank()
            
        })
        
        let grade = UIAction(title: "종합", handler: { _ in
            if self.type == "맞춤(종합)" { return }
            self.navigationItem.title = "주간 종합 랭킹"
            self.type = "종합"
            self.optionButton.setTitle("종합", for: .normal)
        })
        
        let buttonMenu = UIMenu(title: "옵션", image: UIImage(systemName: "list.bullet") , children: [me, gender, age, grade])
        
        optionButton.menu = buttonMenu
        optionButton.showsMenuAsPrimaryAction = true
        optionButton.fs_width = 30
        // ios 15 이상
//        optionButton.changesSelectionAsPrimaryAction = true
        
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "주간 랭킹"
        
        // backBarButtonTitle 설정
//        let backBarButtonItem = UIBarButtonItem(title: "이전 페이지", style: .plain, target: self, action: nil)
//        navigationItem.backBarButtonItem = backBarButtonItem
    }
}
