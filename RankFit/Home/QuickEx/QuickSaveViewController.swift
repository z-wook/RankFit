//
//  QuickSaveViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/01.
//

import UIKit
import Combine

class QuickSaveViewController: UIViewController {

    @IBOutlet weak var selectedCollectionView: UICollectionView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionHeight: NSLayoutConstraint!
    
    let viewModel = ExerciseListViewModel(items: ExerciseInfo.sortedList)
    let searchBar = UISearchBar()
    let selectedEx = CurrentValueSubject<[ExerciseInfo]?, Never>(nil)
    var subscriptions = Set<AnyCancellable>()
    var count: Int! // 이전 뷰에서 넘어온 운동 시간
    var reloading = false
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var selectDataSource: UICollectionViewDiffableDataSource<Section, Item>!
    typealias Item = ExerciseInfo
    enum Section {
        case selected
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        embedSearchBar()
        configureNavigationBar()
        configSelectedCollectionView()
        configCollectionView()
        bind()
    }
    
    private func bind() {
        selectedEx.receive(on: RunLoop.main).sink { selectedList in
            guard let selectedList = selectedList else { return }
            self.applySelectedItem(items: selectedList)
        }.store(in: &subscriptions)
    }
    
    @IBAction func deleteEx(_ sender: UIButton) {
        guard var list = selectedEx.value else { return }
        let item = list[sender.tag]
        print("item: \(item)")
        reloading = true
        list.remove(at: sender.tag)
        selectedEx.send(list)
    }
}

extension QuickSaveViewController {
    private func configSelectedCollectionView() {
        selectDataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: selectedCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuickSelectExCell", for: indexPath) as? QuickSelectExCell else { return nil }
            cell.configure(info: itemIdentifier)
            cell.deleteBtn.tag = indexPath.item
            return cell
        })
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.selected])
        snapshot.appendItems([])
        selectDataSource.apply(snapshot)
        
        selectedCollectionView.delegate = self
    }
    
    private func configCollectionView() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuickExPickerCell", for: indexPath) as? QuickExPickerCell else { return nil }
            cell.configure(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([])
        dataSource.apply(snapshot)
        
        collectionView.delegate = self
        collectionView.isHidden = true
    }
    
    private func applySelectedItem(items: [ExerciseInfo]) {
        if items.isEmpty { updateHeight(empty: true) }
        else { updateHeight(empty: false) }
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.selected])
        snapshot.appendItems(items, toSection: .selected)
        selectDataSource.apply(snapshot)
        
        if reloading {
            // 오직 데이터만 reload
            snapshot.reloadSections([.selected])
            selectDataSource.apply(snapshot)
            reloading = false
        }
    }
    
    private func applyItem(items: [ExerciseInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot)
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func updateHeight(empty: Bool) {
        if empty {
            self.collectionHeight.constant = 0
        } else {
            self.collectionHeight.constant = 50
        }
    }
}

extension QuickSaveViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        if collectionView == selectedCollectionView {
            print("index: \(selectedEx.value?[indexPath.item])")
            return
        }
        searchBar.text = nil
        viewModel.didSelect(at: indexPath)
        let exInfo = viewModel.selectedItem.value
        guard let exInfo = exInfo else { return }
        guard var list = selectedEx.value else {
            selectedEx.send([exInfo])
            applyItem(items: [])
            self.collectionView.isHidden = true
            return
        }
        let result = list.contains { info in
            if info.exerciseName == exInfo.exerciseName { return true }
            else { return false }
        }
        if result {
            applyItem(items: [])
            collectionView.isHidden = true
        } else {
            list.append(exInfo)
            selectedEx.send(list)
            self.collectionView.isHidden = true
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}

extension QuickSaveViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let exName = viewModel.selectedItem.value?.exerciseName else { return .zero }
        let size = calculateCellWidth(text: exName)
        return CGSize(width: size.0, height: size.1)
    }
    
    private func calculateCellWidth(text: String) -> (CGFloat, CGFloat) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.sizeToFit()
        return (label.frame.width + 20, label.frame.height + 20)
    }
}

extension QuickSaveViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            collectionView.isHidden = true
            searchExercise(with: "")
            return
        }
        collectionView.isHidden = false
        searchExercise(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let keyword = searchBar.text, !keyword.isEmpty else { return }
        searchBar.endEditing(true)
    }
}

extension QuickSaveViewController {
    private func embedSearchBar() {
        self.navigationItem.titleView = searchBar
        searchBar.placeholder = "검색"
        searchBar.delegate = self
    }
    
    private func configureNavigationBar() {
        let moreConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "plus"),
            handler: { print("--> more tapped") }
        )
        let moreItem = UIBarButtonItem.generate(with: moreConfig, width: 30)
        navigationItem.rightBarButtonItems = [moreItem]
    }
    
    private func searchExercise(with text: String) {
        var items: [ExerciseInfo] = []
        if text != "" {
            viewModel.filteredExercises(filter: text)
            items = viewModel.items.value
        }
        applyItem(items: items)
    }
}
