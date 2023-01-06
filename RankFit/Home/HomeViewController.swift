//
//  HomeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import Alamofire
import Charts

class HomeViewController: UIViewController {
    
    @IBOutlet weak var barChartView: BarChartView!
    
    let viewModel = HomeViewModel()
    var days: [String] = ["월", "화", "수", "목", "금", "토", "일"]
    var percents: [Double] = []
    
//    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
//
//    typealias Item = String
//    enum Section {
//        case main
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        percents = viewModel.getPercentList()
        setChart(dataPoints: days, values: percents)
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        
        let check = values.filter { $0 == 0 }
        if check.count == 7 {
            barChartView.noDataText = """
                                    완료한 운동이 없습니다.
                                    운동을 완료해 주세요.
                                    """
            barChartView.noDataFont = .systemFont(ofSize: 20)
            barChartView.noDataTextColor = .lightGray
            return
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
        
        barChartView.xAxis.labelPosition = .bottom
        // X축 레이블 포맷 지정
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        barChartView.rightAxis.enabled = false
        
        // 기본 애니메이션
        barChartView.animate(xAxisDuration: 1.3, yAxisDuration: 2.0)
        // 옵션 애니메이션
//        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
        
        // 리미트라인
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
    }
    
    private func configBarChartView() {
        barChartView.noDataText = "데이터가 없습니다."
        barChartView.noDataFont = .systemFont(ofSize: 20)
        barChartView.noDataTextColor = .lightGray
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if Core.shared.isNewUser() {
            // show Onboarding
            let sb = UIStoryboard(name: "Onboarding", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingViewController
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
    
    @IBAction func test(_ sender: UIButton) {

        let parameters: Parameters = [
            "userID": getUserInfo().getUserID(),
            "userAge": getUserInfo().getAge()
        ]

        AF.request("http://rankfit.site/AgeRank.php", method: .post, parameters: parameters).responseJSON {
            response in
            switch response.result {
            case .success(let values):
                let data = values as! NSDictionary
                print("data: \(data)")
                let aaa = data["My_Ranking"] as! String

                print(aaa)

                let bbb = data["count"] as! Int
                print(bbb)

            case .failure(let error):
                print("error!!!: \(error)")
                break;
            }
        }
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
