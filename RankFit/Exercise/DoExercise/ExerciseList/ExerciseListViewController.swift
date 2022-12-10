//
//  ExerciseListViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine

class ExerciseListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var items: [ExerciseInfo] = ExerciseInfo.sortedList
    
    typealias Item = ExerciseInfo
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    var subscriptions = Set<AnyCancellable>()
    var viewModel: ExerciseListViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        embedSearchBar()
        configureCollectionView()
        bind()
    }
    
    private func bind() {
        viewModel.selectedItem
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { selectedExercise in
                
                switch selectedExercise.group {
                case 1, 2:
                    let sb = UIStoryboard(name: "saveExercise", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "saveExerciseViewController1") as! saveExerciseViewController1
                    vc.viewModel = saveExerciseViewModel(DetailItem: selectedExercise)
                    self.present(vc, animated: true)
                    
                case 3:
                    let sb = UIStoryboard(name: "saveExercise", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "saveExerciseViewController2") as! saveExerciseViewController2
                    vc.viewModel = saveExerciseViewModel(DetailItem: selectedExercise)
                    self.present(vc, animated: true)
                    
                default:
                    let sb = UIStoryboard(name: "saveExercise", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "saveExerciseViewController1") as! saveExerciseViewController1
                    vc.viewModel = saveExerciseViewModel(DetailItem: selectedExercise)
                    self.present(vc, animated: true)
                }
//                self.navigationController?.pushViewController(vc, animated: true)
            }.store(in: &subscriptions)
    }
  
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseInfoCell", for: indexPath) as? ExerciseInfoCell else { return nil }
            cell.configure(item: itemIdentifier)
            return cell
        })

        collectionView.collectionViewLayout = layout()
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)

        collectionView.delegate = self
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    private func configureNavigationBar() {
        let moreConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "ellipsis"),
            handler: { print("--> more tapped") }
        )
        let moreItem = UIBarButtonItem.generate(with: moreConfig, width: 30)

        let shareConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "square.and.arrow.up"),
            handler: { print("--> share tapped") }
        )
        let shareItem = UIBarButtonItem.generate(with: shareConfig, width: 30)

        navigationItem.rightBarButtonItems = [moreItem, shareItem]
        navigationItem.backButtonDisplayMode = .minimal
    }

    private func embedSearchBar() {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        self.navigationItem.titleView = searchBar
        searchBar.delegate = self
    }
    
    func searchExercise(with text: String) {
        viewModel.filteredExercises(filter: text)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.items.value, toSection: .main)
        datasource.apply(snapshot)
    }
}

extension ExerciseListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchExercise(with: searchText)
    }
    
    // 없어도 될거같다.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let keyword = searchBar.text, !keyword.isEmpty else { return }
        print("---> key word: \(keyword)")
        searchBar.endEditing(true)
    }
}

extension ExerciseListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelect(at: indexPath)
    }
}
