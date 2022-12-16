//
//  ExerciseViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Combine
import FSCalendar
import CoreData

class ExerciseViewController: UIViewController {

    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    static var today: String!
    static var pickDate: String = ""
    var removeBtnTapState = false
    let dateFormatter = DateFormatter()
    
    let viewModel = ExerciseViewModel()
    var subscriptions = Set<AnyCancellable>()
    
    typealias Item = AnyHashable
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        createCalender()
        updateNavigationItem()
        configureCollectionView()
        bind()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        let todayDate = calendarView.today!
        let today = dateFormatter.string(from: todayDate)
        ExerciseViewController.today = today
        
        viewModel.selectDate(date: ExerciseViewController.pickDate)
    }

    @IBAction func removeBtnTapped(_ sender: UIButton) {
        removeBtnTapState = true
    }
    
    @IBAction func startExerciseBtn(_ sender: UIButton) {
        // 시작 버튼 눌렀을 때 인덱스 번호를 통해 운동정보 전달
        let info = viewModel.storedExercises
        let exerciseTypeInfo = info.value[sender.tag]
        
        let sb = UIStoryboard(name: "DoExercise", bundle: nil)
        
        if ((exerciseTypeInfo as? anaerobicExerciseInfo) != nil) {
            let vc = sb.instantiateViewController(withIdentifier: "AnaerobicActivityViewController") as! AnaerobicActivityViewController
            vc.viewModel = DoExerciseViewModel(ExerciseInfo: exerciseTypeInfo)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if ((exerciseTypeInfo as? aerobicExerciseInfo) != nil) {
            let vc = sb.instantiateViewController(withIdentifier: "AerobicActivityViewController") as! AerobicActivityViewController
            vc.viewModel = DoExerciseViewModel(ExerciseInfo: exerciseTypeInfo)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExercisePlanCell", for: indexPath) as? ExercisePlanCell else { return nil }
            cell.configure(item: itemIdentifier, vm: self.viewModel) // 여기서 셀 설정됨
            cell.startBtn.tag = indexPath.item
            
            print("item: \(itemIdentifier)")
            
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
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
//        section.interGroupSpacing = 10
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func applyItems(items: [AnyHashable]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
        
        if removeBtnTapState {
            // 오직 데이터만 reload
            snapshot.reloadSections([.main])
            datasource.apply(snapshot)
            removeBtnTapState = false
        }
    }
    
    private func bind() {
        viewModel.storedExercises
            .receive(on: RunLoop.main)
            .sink { exerciseList in
                print("exerciseList: \(exerciseList)")
                self.applyItems(items: exerciseList)
            }.store(in: &subscriptions)
    }
}

extension ExerciseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("select: \(indexPath.item)")
    }
}

extension ExerciseViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    func createCalender() {
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.scrollDirection = .horizontal
        calendarView.appearance.titleFont = UIFont(name: "NotoSansKR-Regular", size: 14)

        let todayDate = calendarView.today!
        let defaultDate = dateFormatter.string(from: todayDate)
        ExerciseViewController.today = defaultDate
        ExerciseViewController.pickDate = defaultDate
        viewModel.selectDate(date: defaultDate)
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // 자정 지나는 상황을 위해 클릭마다 오늘 날짜 업데이트
        let today = dateFormatter.string(from: calendarView.today!)
        ExerciseViewController.today = today
        
        // 클릭하는 날짜 업데이트
        let selectDate = dateFormatter.string(from: date)
        
        // 날짜 클릭때마다 read는 비효율적이니까 이전 클릭했던 날짜랑 비교해서 다르면 read하기
        if ExerciseViewController.pickDate != selectDate {
            ExerciseViewController.pickDate = selectDate
            viewModel.selectDate(date: selectDate)
        }
    }
}

extension ExerciseViewController {
    
    private func updateNavigationItem() {
        let titleConfig = CustomBarItemConfiguration(
            title: "운동",
            handler: { }
        )
        let titleItem = UIBarButtonItem.generate(with: titleConfig)
        
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

        navigationItem.leftBarButtonItem = titleItem
        navigationItem.rightBarButtonItems = [feedItem]
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
