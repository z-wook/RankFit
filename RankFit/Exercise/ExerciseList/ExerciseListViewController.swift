//
//  ExerciseListViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine

class ExerciseListViewController: UIViewController {

    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let viewModel = ExerciseListViewModel(items: ExerciseInfo.sortedList)
    let searchBar = UISearchBar()
    var categoryDataSource: UICollectionViewDiffableDataSource<Section, String>!
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var subscriptions = Set<AnyCancellable>()
    
    typealias Item = ExerciseInfo
    enum Section {
        case main
    }
    let category = ["전체", "가슴", "등", "복부", "상체", "어깨", "유산소", "전신", "팔", "하체"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        embedSearchBar()
        configureCategories()
        configureCollectionView()
        bind()
    }
    
    private func bind() {
        viewModel.selectedItem
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] selectedExercise in
                guard let self = self else { return }
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
                    
                default: // group4 == 플랭크 운동
                    let sb = UIStoryboard(name: "saveExercise", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "savePlankViewController") as! savePlankViewController
                    vc.viewModel = saveExerciseViewModel(DetailItem: selectedExercise)
                    self.present(vc, animated: true)
                }
            }.store(in: &subscriptions)
    }
    
    private func configureCategories() {
        categoryDataSource = UICollectionViewDiffableDataSource<Section, String>(collectionView: categoriesCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as? CategoryCell else { return nil }
            cell.configure(categoryName: itemIdentifier)
            return cell
        })
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(category)
        categoryDataSource.apply(snapshot)
        
        categoriesCollectionView.selectItem(at: [0, 0], animated: true, scrollPosition: .left)
        categoriesCollectionView.delegate = self
    }
    
    private func configureCollectionView() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseInfoCell", for: indexPath) as? ExerciseInfoCell else { return nil }
            cell.configure(item: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.items.value, toSection: .main)
        dataSource.apply(snapshot)
        
        collectionView.delegate = self
    }
    
    private func applyItems(items: [ExerciseInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot)
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
    
    private func embedSearchBar() {
        self.navigationItem.titleView = searchBar
        searchBar.placeholder = "검색"
        searchBar.delegate = self
    }
    
    private func searchExercise(with text: String) {
        viewModel.filteredExercises(filter: text)
        applyItems(items: viewModel.items.value)
    }
}

extension ExerciseListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoriesCollectionView {
            let categoryName = category[indexPath.item]
            let size = calculateCellWidth(text: categoryName)
            return CGSize(width: size.0, height: size.1)
        } else {
            return .zero
        }
    }
    
    private func calculateCellWidth(text: String) -> (CGFloat, CGFloat) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.sizeToFit()
        return (label.frame.width, label.frame.height)
    }
}

extension ExerciseListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchExercise(with: searchText)
        categoriesCollectionView.reloadData()
        if searchText == "" {
            categoriesCollectionView.selectItem(at: [0, 0], animated: true, scrollPosition: .left)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let keyword = searchBar.text, !keyword.isEmpty else { return }
        searchBar.endEditing(true)
    }
}

extension ExerciseListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        if collectionView == categoriesCollectionView {
            let categoryName = category[indexPath.item]
            viewModel.get_category(categoryName: categoryName)
            applyItems(items: viewModel.items.value)
        } else {
            viewModel.didSelect(at: indexPath)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}
