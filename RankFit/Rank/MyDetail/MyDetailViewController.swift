//
//  MyDetailViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/02.
//

import UIKit
import Combine

class MyDetailViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var exercise: String!
    var rank: String!
    var score: String!
    
    
    typealias Item = String
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    let aaa = CurrentValueSubject<String, Never>("")
    var subscriptions = Set<AnyCancellable>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureCollectionView()
        bind()
    }
    
    func myInfo(title: String, rank: String, score: String) {
        self.exercise = title
        self.rank = rank
        self.score = score
    }
    
    func configure() {
//        exerciseLabel.text = exercise
//        myRank.text = rank
//        myScore.text = score
//        self.navigationItem.title = "랭킹"
        
        self.navigationItem.title = exercise
//        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    private func bind() {
        aaa.receive(on: RunLoop.main)
            .sink { result in
//                applyItems(items: <#T##[String]#>)
            }.store(in: &subscriptions)
    }
}

extension MyDetailViewController {
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyDetailCell", for: indexPath) as? MyDetailCell else { return nil }
//            cell.config(rank: <#T##Int#>, nickname: <#T##String#>, score: <#T##Int#>)
            return cell
        })
        
        collectionView.collectionViewLayout = layout()

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
    }
    
    private func applyItems(items: [String]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
    }

    private func layout() -> UICollectionViewCompositionalLayout {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
