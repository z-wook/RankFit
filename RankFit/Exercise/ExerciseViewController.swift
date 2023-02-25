//
//  ExerciseViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import FSCalendar
import CoreData
import FirebaseAuth
import Combine

class ExerciseViewController: UIViewController {

    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    let viewModel = ExerciseViewModel()
    let dateFormatter = DateFormatter()
    static var reloadEx = PassthroughSubject<Bool, Never>()
    let serverState = PassthroughSubject<Bool, Never>()
    let firebaseState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    static var today: String!
    static var pickDate: String = ""
    var exUUID: UUID!
    var exEntityName: String!
    var reloading = false
    
    typealias Item = AnyHashable
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        createCalender()
        updateNavigationItem()
        configCollectionView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.selectDate(date: ExerciseViewController.pickDate)
    }
    
    private func bind() {
        ExerciseViewController.reloadEx.receive(on: RunLoop.main).sink { _ in
            print("Exercise Reload")
            self.viewModel.selectDate(date: ExerciseViewController.pickDate)
        }.store(in: &subscriptions)
        
        viewModel.storedExercises.receive(on: RunLoop.main).sink { exerciseList in
            print("exerciseList: \(exerciseList)")
            self.applyItems(items: exerciseList)
        }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            if result == true {
                configFirebase.deleteEx(
                    date: ExerciseViewController.pickDate,
                    uuid: self.exUUID.uuidString,
                    subject: self.firebaseState)
            } else {
                print("서버 운동 삭제 실패")
                self.showAlert()
            }
        }.store(in: &subscriptions)
        
        firebaseState.receive(on: RunLoop.main).sink { result in
            if result == true {
                print("Firebase에서 운동 삭제 성공")
                let deleteState = ExerciseCoreData.deleteCoreData(id: self.exUUID, entityName: self.exEntityName) // return T/F
                if deleteState {
                    self.viewModel.selectDate(date: ExerciseViewController.pickDate)
                } else {
                    print("CoreData 삭제 실패")
                    configFirebase.errorReport(type: "ExerciseVC.bind_firebaseState", descriptions: "CoreData에서 운동 삭제 실패")
                    self.showAlert()
                }
            } else {
                print("Firebase에서 운동 삭제 실패")
            }
        }.store(in: &subscriptions)
    }
    
    @IBAction func deleteExBtn(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert(type: "삭제")
            return
        }
        deleteOK(index: sender.tag, deleteBtn: sender)
    }
    
    @IBAction func startExerciseBtn(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert(type: "시작")
            return
        }
        // 시작 버튼 눌렀을 때 인덱스 번호를 통해 운동정보 전달
        reloading = true
        let info = viewModel.storedExercises
        let exTypeInfo = info.value[sender.tag]
        let sb = UIStoryboard(name: "DoExercise", bundle: nil)
        if let anaeroEx = exTypeInfo as? anaerobicExerciseInfo {
            if anaeroEx.exercise == "플랭크" {
                let vc = sb.instantiateViewController(withIdentifier: "PlankActivityViewController") as! PlankActivityViewController
                vc.viewModel = DoExerciseViewModel(ExerciseInfo: exTypeInfo)
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                let vc = sb.instantiateViewController(withIdentifier: "AnaerobicActivityViewController") as! AnaerobicActivityViewController
                vc.viewModel = DoExerciseViewModel(ExerciseInfo: exTypeInfo)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            let vc = sb.instantiateViewController(withIdentifier: "AerobicActivityViewController") as! AerobicActivityViewController
            vc.viewModel = DoExerciseViewModel(ExerciseInfo: exTypeInfo)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ExerciseViewController {
    private func configCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExercisePlanCell", for: indexPath) as? ExercisePlanCell else { return nil }
            cell.configure(item: itemIdentifier, vm: self.viewModel)
            cell.deleteBtn.tag = indexPath.item
            cell.startBtn.tag = indexPath.item
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
        
        if reloading {
            // 오직 데이터만 reload
            snapshot.reloadSections([.main])
            datasource.apply(snapshot)
            reloading = false
        }
    }
    
    private func loginAlert(type: String) {
        let alert = UIAlertController(title: "로그아웃 상태", message: "현재 로그아웃 되어있어 운동을 \(type)할 수 없습니다.\n로그인을 먼저 해주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "운동 삭제 실패", message: "잠시 후 다시 시도해 주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteOK(index: Int, deleteBtn: UIButton) {
        let alert = UIAlertController(title: "운동을 삭제하시겠습니까?", message: nil, preferredStyle: .actionSheet)
        let ok = UIAlertAction(title: "삭제", style: .destructive) { action in
            self.reloading = true
            deleteBtn.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                deleteBtn.isEnabled = true
            }
            let info = self.viewModel.storedExercises
            let exTypeInfo = info.value[index]
            guard let aerobicInfo = exTypeInfo as? aerobicExerciseInfo else {
                let anaerobicInfo = exTypeInfo as! anaerobicExerciseInfo
                self.exUUID = anaerobicInfo.id
                self.exEntityName = "Anaerobic"
                SendAnaerobicEx.sendDeleteEx(info: anaerobicInfo, subject: self.serverState)
                return
            }
            self.exUUID = aerobicInfo.id
            self.exEntityName = "Aerobic"
            SendAerobicEx.sendDeleteEx(info: aerobicInfo, subject: self.serverState)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
}

extension ExerciseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("list: \(viewModel.storedExercises.value[indexPath.item])")
    }
}

extension ExerciseViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    func createCalender() {
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.scope = .month
        calendarView.scrollDirection = .horizontal
        // 헤더 폰트 설정
        calendarView.appearance.headerTitleFont = UIFont(name: "NotoSansKR-Medium", size: 16)
        // Weekday 폰트 설정
        calendarView.appearance.weekdayFont = UIFont(name: "NotoSansKR-Regular", size: 14)
        // 각각의 일(날짜) 폰트 설정
        calendarView.appearance.titleFont = UIFont(name: "NotoSansKR-Regular", size: 15)
        
        calendarView.layer.cornerRadius = 20
        
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
