//
//  RankViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine

class RankViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    var list: [String] = [] // 사용자 목록
    
    typealias Item = String
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateNavigationItem()
        
        
        for i in 1...30 {
            list.append("\(i)")
        }
        
        configureCollectionView()
    }
}

extension RankViewController {
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RankCell", for: indexPath) as? RankCell else {
                return nil
            }
            cell.config(info: self.list[indexPath.item])
            return cell
        })
        
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(list, toSection: .main)
        datasource.apply(snapshot)
        
        collectionView.delegate = self
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
//    private func applyItems(items: [AnyHashable]) {
//
//    }
}

extension RankViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("click: \(indexPath.item)")
    }
}

extension RankViewController {
    private func updateNavigationItem() {
        let titleConfig = CustomBarItemConfiguration(
            title: "랭킹",
            handler: { }
        )
//        let titleItem = UIBarButtonItem.generate(with: titleConfig)
        
        let feedConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "plus"),
            handler: {
                let sb = UIStoryboard(name: "ExerciseList", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "ExerciseListViewController") as! ExerciseListViewController
                vc.viewModel = ExerciseListViewModel(items: ExerciseInfo.sortedList)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        )
        let feedItem = UIBarButtonItem.generate(with: feedConfig, width: 30)

//        navigationItem.leftBarButtonItem = titleItem
        navigationItem.rightBarButtonItems = [feedItem]
//        navigationItem.title = "운동"
        
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationItem.backButtonDisplayMode = .minimal
//        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "주간 랭킹"
        
        
        
        // backBarButtonTitle 설정
//        let backBarButtonItem = UIBarButtonItem(title: "이전 페이지", style: .plain, target: self, action: nil)
//        navigationItem.backBarButtonItem = backBarButtonItem
    }
}
