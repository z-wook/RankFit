//
//  OptionRankViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/01.
//

import UIKit
import FSCalendar

class OptionRankViewController: UIViewController {

    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    static var today: String!
    static var pickDate: String = ""
    let dateFormatter = DateFormatter()
    
    var list: [String] = []
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    typealias Item = String
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        dateFormatter.dateFormat = "yyyy/MM/dd"
        createCalender()
        for i in 1...30 {
            list.append("\(i)")
        }

        configCollectionView()
        
    }
}

extension OptionRankViewController: UICollectionViewDelegate {
    func configCollectionView() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionRankCell", for: indexPath) as? OptionRankCell else { return nil }
            cell.config(info: itemIdentifier)
            return cell
        })

        collectionView.collectionViewLayout = layout()

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(list, toSection: .main)
        dataSource.apply(snapshot)

        collectionView.delegate = self
    }

    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(60))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(60))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension OptionRankViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    func createCalender() {
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.scope = .week
        calendarView.firstWeekday = 2 // 월요일 부터 시작
        calendarView.scrollDirection = .horizontal

        // 헤더 폰트 설정
//        calendarView.appearance.headerTitleFont = UIFont(name: "NotoSansKR-Medium", size: 40)
//
//        // Weekday 폰트 설정
//        calendarView.appearance.weekdayFont = UIFont(name: "NotoSansKR-Regular", size: 40)
//
//        // 각각의 일(날짜) 폰트 설정
//        calendarView.appearance.titleFont = UIFont(name: "NotoSansKR-Regular", size: 40)

        // 캘린더의 cornerRadius 지정
        calendarView.layer.cornerRadius = 20


        let todayDate = calendarView.today!
        let defaultDate = dateFormatter.string(from: todayDate)
        ExerciseViewController.today = defaultDate
        ExerciseViewController.pickDate = defaultDate
//        viewModel.selectDate(date: defaultDate)
    }

    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarView.frame.size.height = bounds.height
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
//            viewModel.selectDate(date: selectDate)
        }
    }
}
