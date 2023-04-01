//
//  HomeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import SwiftUI
import Alamofire
import Charts
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import Combine

class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var weeklyRankBackground: UIView!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var radarChartView: RadarChartView!
    
    let rankSubject = CurrentValueSubject<[WeeklyRank]?, Never>(nil)
    var subscriptions = Set<AnyCancellable>()
    
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
        setRadarChart(week: [], month: [])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        let weekList = viewModel.getCategoryList(type: "week")
        let monthList = viewModel.getCategoryList(type: "month")
        weekRankVM.getWeeklyRank(subject: rankSubject)
        setRadarChart(week: weekList, month: monthList)
        
        let current_percent = viewModel.getPercentList()
        // 이전이랑 퍼센트가 같다면 차트 업로드 안함
        if prev_percents == current_percent { return }
        prev_percents = current_percent
        setChart(dataPoints: days, values: current_percent)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
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
                    print("error: \(error.localizedDescription)")
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
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert(type: "빠른 운동")
            return
        }
        let sb = UIStoryboard(name: "QuickExercise", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "QuickAerobicViewController") as! QuickAerobicViewController
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeViewController {
    private func configure() {
//        weeklyRankBackground.backgroundColor = UIColor.cyan.withAlphaComponent(0.6)
        weeklyRankBackground.backgroundColor = UIColor(named: "baseColor")
        weeklyRankBackground.layer.cornerRadius = 20
        pageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        pageLabel.clipsToBounds = true
        pageLabel.layer.cornerRadius = 15
    }
    
    private func updateNavigationItem() {
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = UIColor(named: "link_cyan")
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func bind() {
        rankSubject.receive(on: RunLoop.main).sink { list in
            guard let list = list else { return }
            if list.isEmpty {
                self.pageLabel.layer.isHidden = true
                self.applyItems(items: [WeeklyRank(rank: "이번 주 인기 운동이 초기화되었습니다.", exercise: "")])
                return
            } else {
                DispatchQueue.main.async {
                    self.pageLabel.layer.isHidden = false
                    self.pageLabel.text = "1 / \(list.count)"
                }
                self.applyItems(items: list)
                self.bannerTimer()
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
        snapshot.appendItems([WeeklyRank(rank: "이번 주 인기 운동", exercise: "")], toSection: .main)
        datasource.apply(snapshot)
        
        collectionView.delegate = self
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
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
    
    private func loginAlert(type: String) {
        let alert = UIAlertController(title: "로그아웃 상태", message: "현재 로그아웃 되어있어 운동을 \(type)을 할 수 없습니다.\n로그인을 먼저 해주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
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
        
        // limit line
        let ll = ChartLimitLine(limit: 50.0, label: "50%")
        barChartView.leftAxis.addLimitLine(ll)
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.drawAxisLineEnabled = false
        barChartView.rightAxis.drawAxisLineEnabled = false
        barChartView.leftAxis.drawAxisLineEnabled = false
        barChartView.leftAxis.drawLabelsEnabled = false
        barChartView.leftAxis.gridColor = .clear
        barChartView.noDataText = "완료한 운동이 없습니다.\n운동을 완료해 주세요."
        barChartView.noDataFont = .systemFont(ofSize: 20)
        barChartView.noDataTextColor = .label
        
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
    
    func setRadarChart(week: [String], month: [String]) {
        let greenDataSet = RadarChartDataSet(   // 최근 한달
            entries: [
                RadarChartDataEntry(value: Double(month.filter { $0 == "가슴" }.count)), // 가슴
                RadarChartDataEntry(value: Double(month.filter { $0 == "등" }.count)), // 등
                RadarChartDataEntry(value: Double(month.filter { $0 == "복부" }.count)), // 복부
                RadarChartDataEntry(value: Double(month.filter { $0 == "상체" }.count)), // 상체
                RadarChartDataEntry(value: Double(month.filter { $0 == "어께" }.count)), // 어께
                RadarChartDataEntry(value: Double(month.filter { $0 == "유산소" }.count)), // 유산소
                RadarChartDataEntry(value: Double(month.filter { $0 == "전신" }.count)), // 전신
                RadarChartDataEntry(value: Double(month.filter { $0 == "팔" }.count)), // 팔
                RadarChartDataEntry(value: Double(month.filter { $0 == "하체" }.count)) // 하체
            ]
        )
        let redDataSet = RadarChartDataSet(     // 최근 일주일
            entries: [
                RadarChartDataEntry(value: Double(week.filter { $0 == "가슴" }.count)), // 가슴
                RadarChartDataEntry(value: Double(week.filter { $0 == "등" }.count)), // 등
                RadarChartDataEntry(value: Double(week.filter { $0 == "복부" }.count)), // 복부
                RadarChartDataEntry(value: Double(week.filter { $0 == "상체" }.count)), // 상체
                RadarChartDataEntry(value: Double(week.filter { $0 == "어께" }.count)), // 어께
                RadarChartDataEntry(value: Double(week.filter { $0 == "유산소" }.count)), // 유산소
                RadarChartDataEntry(value: Double(week.filter { $0 == "전신" }.count)), // 전신
                RadarChartDataEntry(value: Double(week.filter { $0 == "팔" }.count)), // 팔
                RadarChartDataEntry(value: Double(week.filter { $0 == "하체" }.count)) // 하체
            ]
        )
        let data = RadarChartData(dataSets: [greenDataSet, redDataSet])
        radarChartView.data = data
        redDataSet.lineWidth = 2
        greenDataSet.lineWidth = 2

        let redColor = UIColor(red: 247/255, green: 67/255, blue: 115/255, alpha: 1)
        let redFillColor = UIColor(red: 247/255, green: 67/255, blue: 115/255, alpha: 0.6)
        redDataSet.colors = [redColor]
        redDataSet.fillColor = redFillColor
        redDataSet.drawFilledEnabled = true
        
        let greenColor = UIColor(red: 67/255, green: 247/255, blue: 115/255, alpha: 1)
        let greenFillColor = UIColor(red: 67/255, green: 247/255, blue: 115/255, alpha: 0.6)
        greenDataSet.colors = [greenColor]
        greenDataSet.fillColor = greenFillColor
        greenDataSet.drawFilledEnabled = true
        
        redDataSet.valueFormatter = DataSetValueFormatter()
        greenDataSet.valueFormatter = DataSetValueFormatter()
        
        radarChartView.webLineWidth = 1.5
        radarChartView.innerWebLineWidth = 1.5
        radarChartView.webColor = .lightGray
        radarChartView.innerWebColor = .lightGray
        
        let xAxis = radarChartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 9, weight: .bold)
        xAxis.labelTextColor = .label
        xAxis.xOffset = 10
        xAxis.yOffset = 10
        xAxis.valueFormatter = XAxisFormatter()

        let yAxis = radarChartView.yAxis
        yAxis.labelFont = .systemFont(ofSize: 9, weight: .light)
        yAxis.labelCount = 6
        yAxis.drawTopYLabelEntryEnabled = false
        yAxis.axisMinimum = 0
        yAxis.valueFormatter = YAxisFormatter()

        radarChartView.rotationEnabled = false
        radarChartView.legend.enabled = false
        radarChartView.setNeedsDisplay()
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

class DataSetValueFormatter: ValueFormatter {
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String { "" }
}

class XAxisFormatter: AxisValueFormatter {
    let titles = ["가슴", "등", "복부", "상체", "어깨", "유산소", "전신", "팔", "하체"]
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        titles[Int(value) % titles.count]
    }
}

class YAxisFormatter: AxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        ""
    }
}

struct RadarView: UIViewRepresentable {
    typealias UIViewType = RadarChartView
        
    func makeUIView(context: UIViewRepresentableContext<RadarView>) -> RadarChartView {
        let radarChart = RadarChartView()
        return radarChart
    }
    
    @State var data: RadarChartData
    func updateUIView(_ uiView: RadarChartView, context: UIViewRepresentableContext<RadarView>) {
        uiView.data = data
    }
}
