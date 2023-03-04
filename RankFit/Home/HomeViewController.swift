//
//  HomeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Alamofire
import Charts
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import Combine

class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    
    static let SuspendNotification = PassthroughSubject<Bool, Never>()
    let rankSubject = CurrentValueSubject<[WeeklyRank]?, Never>(nil)
    let getNotiPermission = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var cancel: Cancellable?
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    let viewModel = HomeViewModel()
    let weekRankVM = WeeklyRankViewModel()
    let days: [String] = ["월", "화", "수", "목", "금", "토", "일"]
    var prev_percents: [Double] = []
    var timer: Timer?
    var nowPage: Int = 0 // 현재페이지 체크 변수 (자동 스크롤할 때 필요)
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    typealias Item = WeeklyRank
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNavigationItem()
        configCollectionView()
        configure()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        weekRankVM.getWeeklyRank(subject: rankSubject)
        
        let current_percent = viewModel.getPercentList()
        // 이전이랑 퍼센트가 같다면 차트 업로드 안함
        if prev_percents == current_percent { return }
        prev_percents = current_percent
        setChart(dataPoints: days, values: current_percent)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
        timer = nil
        cancel?.cancel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if Core.shared.isNewUser() {
            // 복귀 유저를 위해 Firebase 로그아웃 후 저장되있던 keyChain 삭제
            let user = Auth.auth().currentUser
            if user != nil {
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("error: " + error.localizedDescription)
                    configFirebase.errorReport(type: "HomeVC.viewDidLayoutSubviews", descriptions: error.localizedDescription)
                }
            }
            saveUserData.removeKeychain(forKey: .Email)
            saveUserData.removeKeychain(forKey: .UID)
            saveUserData.removeKeychain(forKey: .NickName)
            saveUserData.removeKeychain(forKey: .Gender)
            saveUserData.removeKeychain(forKey: .Birth)
            saveUserData.removeKeychain(forKey: .Weight)
            // show Onboarding
            let sb = UIStoryboard(name: "Onboarding", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingViewController
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
    
    @IBAction func QuickExercise(_ sender: UIButton) {
        quickStart()
    }
    
    @IBAction func Test(_ sender: UIButton) {
        // firebase 이메일 변경
        //        Auth.auth().currentUser?.updateEmail(to: "", completion: { error in
        //            print("error: \(error.debugDescription)")
        //        })
        
//        // 등록 토큰에 엑세스하는 방법
//        Messaging.messaging().token { token, error in
//            if let error = error {
//                print("Error fetching FCM registration token: \(error.localizedDescription)")
//            }
//            else if let token = token {
//                print("FCM registration token: \(token)")
//            }
//        }
        
        let sb = UIStoryboard(name: "QuickExercise", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "QuickSaveViewController") as! QuickSaveViewController
        vc.count = 3
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeViewController {
    private func configure() {
//        backgroundView.backgroundColor = UIColor.link.withAlphaComponent(0.6)
        backgroundView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.6)
        backgroundView.layer.cornerRadius = 20
        pageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        pageLabel.clipsToBounds = true
        pageLabel.layer.cornerRadius = 15
    }
    
    private func updateNavigationItem() {
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func bind() {
        rankSubject.receive(on: RunLoop.main).sink { list in
            guard let list = list else { return }
            if list.isEmpty {
                self.pageLabel.layer.isHidden = true
                self.applyItems(items: [WeeklyRank(rank: "", exercise: "이번 주 인기 운동이 초기화되었습니다.")])
            } else {
                DispatchQueue.main.async {
                    self.pageLabel.text = "1 / \(list.count)"
                }
                self.applyItems(items: list)
                self.bannerTimer()
            }
        }.store(in: &subscriptions)
        
        let suspendSubject = HomeViewController.SuspendNotification
            .receive(on: RunLoop.main).sink { result in
                if result {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "계정 사용 중지됨", message: "귀하의 계정이 사용 중지되었습니다. 문의사항은 관리자에게 해주세요.", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "확인", style: .destructive)
                        alertController.addAction(ok)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        cancel = suspendSubject
        
        getNotiPermission.receive(on: RunLoop.main).sink { result in
            if result {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "알림 수신 거부됨", message: "공지사항을 수신하기 위해 알림 수신을 켜주세요", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                        // 설정으로 이동
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    let cancle = UIAlertAction(title: "취소", style: .default)
                    // 색상 적용.
                    cancle.setValue(UIColor.darkGray, forKey: "titleTextColor")
                    alert.addAction(cancle)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }.store(in: &subscriptions)
    }
    
    private func configCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "weeklyRankCell", for: indexPath) as? weeklyRankCell else {
                return nil
            }
            cell.configure(info: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([WeeklyRank(rank: "", exercise: "이번 주 인기 운동")], toSection: .main)
        datasource.apply(snapshot)
        
        collectionView.delegate = self
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100))
        let itme = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [itme])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applyItems(items: [WeeklyRank]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
    }
    
    private func quickStart() {
        let sb = UIStoryboard(name: "QuickExercise", bundle: nil)
        let alert = UIAlertController(title: "운동 타입을 선택해 주세요.", message: nil, preferredStyle: .actionSheet)
        let anaerobic = UIAlertAction(title: "무산소 운동", style: .default) { _ in
            let vc = sb.instantiateViewController(withIdentifier: "QuickAnaerobicViewController") as! QuickAnaerobicViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let aerobic = UIAlertAction(title: "유산소 운동(러닝 / 싸이클)", style: .default) { _ in
            let vc = sb.instantiateViewController(withIdentifier: "QuickAerobicViewController") as! QuickAerobicViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(anaerobic)
        alert.addAction(aerobic)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("select: \(indexPath.item)")
    }
}

extension HomeViewController {
    private func setChart(dataPoints: [String], values: [Double]) {
        barChartView.xAxis.labelPosition = .bottom
        // X축 레이블 포맷 지정
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        barChartView.rightAxis.enabled = false
        
        // 기본 애니메이션
        barChartView.animate(xAxisDuration: 1.3, yAxisDuration: 2.0)
        // 옵션 애니메이션
//        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
        
        // limit line
        let ll = ChartLimitLine(limit: 50.0, label: "50%")
        barChartView.leftAxis.addLimitLine(ll)
        
        // 백그라운드 컬러
//        barChartView.backgroundColor = .yellow
        
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.drawAxisLineEnabled = false
        barChartView.rightAxis.drawAxisLineEnabled = false
        barChartView.leftAxis.drawAxisLineEnabled = false
        barChartView.leftAxis.drawLabelsEnabled = false
        //        barChartView.legend.enabled = false
        barChartView.leftAxis.gridColor = .clear
        barChartView.noDataText = "완료한 운동이 없습니다.\n운동을 완료해 주세요."
        barChartView.noDataFont = .systemFont(ofSize: 20)
        barChartView.noDataTextColor = .lightGray
        
        let check = values.filter { $0 == 0.0 }
        if check.count == 7 {
            return barChartView.data = nil
        }
        
        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(entries: dataEntries, label: "완료율(%)")
        // 선택 안되게
        chartDataSet.highlightEnabled = false
        // 줌 안되게
        barChartView.doubleTapToZoomEnabled = false
        // 차트 컬러
        chartDataSet.colors = [.link]
        
        // 데이터 삽입
        let chartData = BarChartData(dataSet: chartDataSet)
        barChartView.data = chartData
    }
}

extension HomeViewController: UIScrollViewDelegate {
    private func bannerTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.bannerMove()
        }
    }
    
    private func bannerMove() {
        if let rankList = rankSubject.value {
            // 현재페이지가 마지막 페이지일 경우
            if nowPage == rankList.count-1 {
                // 맨 처음 페이지로 돌아감
                collectionView.scrollToItem(at: NSIndexPath(item: 0, section: 0) as IndexPath, at: .bottom, animated: true)
                nowPage = 0
                DispatchQueue.main.async {
                    self.pageLabel.text = "\(self.nowPage + 1) / \(rankList.count)"
                }
                return
            }
            // 다음 페이지로 전환
            nowPage += 1
            collectionView.scrollToItem(at: NSIndexPath(item: nowPage, section: 0) as IndexPath, at: .bottom, animated: true)
            DispatchQueue.main.async {
                self.pageLabel.text = "\(self.nowPage + 1) / \(rankList.count)"
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.y / self.collectionView.bounds.height)
        guard let count = rankSubject.value?.count else { return }
        DispatchQueue.main.async {
            self.pageLabel.text = "\(index + 1) / \(count)"
            self.nowPage = index
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard let count = rankSubject.value?.count else { return true }
        DispatchQueue.main.async {
            self.pageLabel.text = "\(1) / \(count)"
            self.nowPage = 0
        }
        return true
    }
}

class Core {
    static let shared = Core()
    
    func isNewUser() -> Bool {
        return !UserDefaults.standard.bool(forKey: "isNewUser")
    }
    
    func setIsNotNewUser() {
        UserDefaults.standard.set(true, forKey: "isNewUser")
    }
}
