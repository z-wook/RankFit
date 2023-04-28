//
//  NoticeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/26.
//

import UIKit
import Combine

class NoticeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let viewModel = NoticeViewModel()
    let notiSubject = CurrentValueSubject<[notification]?, Never>(nil)
    var subscriptions = Set<AnyCancellable>()
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    typealias Item = notification
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateNavigationItem()
        configCollectionView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.getNotice(subject: notiSubject)
    }
    
    private func updateNavigationItem() {
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "공지사항"
    }
    
    private func bind() {
        notiSubject.receive(on: RunLoop.main).sink { notiList in
            guard let notiList = notiList else { return }
            self.indicator.stopAnimating()
            self.applyItems(items: notiList)
        }.store(in: &subscriptions)
    }
    
    private func configCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoticeCell", for: indexPath) as? NoticeCell else { return nil }
            cell.configure(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
        
        collectionView.delegate = self
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
        let itme = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [itme])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applyItems(items: [notification]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
    }
}

extension NoticeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let info = notiSubject.value else { return }
        let information = info[indexPath.item]
        let vc = storyboard?.instantiateViewController(withIdentifier: "NoticeDetailViewController") as! NoticeDetailViewController
        vc.info = information
        navigationController?.pushViewController(vc, animated: true)
    }
}
