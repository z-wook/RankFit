//
//  UserDetailViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/01.
//

import UIKit
import FSCalendar
import Combine

class UserDetailViewController: UIViewController {

    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let viewModel = OptionDetailViewModel()
    static var pickDate: String = ""
    let dateFormatter = DateFormatter()
    var nickName: String!
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    var subscriptions = Set<AnyCancellable>()
    
    typealias Item = AnyHashable
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "'" + nickName + "'" + "님의 주간운동"
        dateFormatter.dateFormat = "yyyy-MM-dd"
        createCalender()
        configCollectionView()
        bind()
        indicator.startAnimating()
    }
    
    func userInfo(nickName: String) {
        self.nickName = nickName
        viewModel.getDetailExInfo(nickName: nickName)
    }
    
    private func bind() {
        viewModel.infoSubject.receive(on: RunLoop.main).sink { info in
            guard let info = info else { return }
            self.indicator.stopAnimating()
            if info.isEmpty {
                self.applyItems(items: [])
                return
            }
            let date = OptionDetailViewController.pickDate
            let exercises = self.viewModel.getUserExercises(data: info, date: date)
            self.applyItems(items: exercises)
        }.store(in: &subscriptions)
    }
}

extension UserDetailViewController: UICollectionViewDelegate {
    func configCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyDetailCell", for: indexPath) as? MyDetailCell else { return nil }
            cell.configure(item: itemIdentifier)
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applyItems(items: [AnyHashable]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
    }
}

extension UserDetailViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    private func createCalender() {
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.scope = .week
        calendarView.firstWeekday = 2 // 월요일 부터 시작
        calendarView.scrollDirection = .horizontal
        // 캘린더의 cornerRadius 지정
        calendarView.layer.cornerRadius = 20
        let todayDate = calendarView.today!
        let defaultDate = dateFormatter.string(from: todayDate)
        OptionDetailViewController.pickDate = defaultDate
    }

    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarView.frame.size.height = bounds.height
    }


    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // 클릭하는 날짜 업데이트
        let selectDate = dateFormatter.string(from: date)

        // 날짜 클릭때마다 read는 비효율적이니까 이전 클릭했던 날짜랑 비교해서 다르면 read하기
        if OptionDetailViewController.pickDate != selectDate {
            OptionDetailViewController.pickDate = selectDate
            let data = viewModel.infoSubject.value
            guard let data = data else { return }
            let exercises = viewModel.getUserExercises(data: data, date: selectDate)
            applyItems(items: exercises)
        }
    }
}
