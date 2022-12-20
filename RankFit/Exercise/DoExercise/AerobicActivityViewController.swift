//
//  AerobicActivityViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import MapKit
import CoreLocation
import Foundation
import CoreMotion

class AerobicActivityViewController: UIViewController {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var goalDistance: UILabel!
    @IBOutlet weak var goalTime: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var moveDistance: UILabel!
    @IBOutlet weak var currentSpeed: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var state: UILabel!
    
    var viewModel: DoExerciseViewModel!
    var timer: Timer?
    let interval = 1.0
    var count = 0
    
    var locationManager: CLLocationManager?
    var motionManager: CMMotionActivityManager?
    
    var previousLocation: CLLocation? // 이전 위치 정보 저장
    var totalDistance: Double = 0 // 실제 움직인 거리 m
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        requestLocationAuthorization() // location config & permission
        
//        requestActivityAuthorization()
        
        self.mapView.isZoomEnabled = true
        self.mapView.delegate = self
//        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 정지할 이유가 없다.
//        self.locationManager?.stopUpdatingLocation()
//        self.motionManager?.stopActivityUpdates()
        
        timer?.invalidate()
    }

    @IBAction func currentLocationBtn(_ sender: UIButton) {
        let status = locationManager?.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.mapView.showsUserLocation = true
            self.mapView.setUserTrackingMode(.follow, animated: true)

        default:
            showAlert(reason: "GPS 권한 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
        }
        
        if locationManager?.accuracyAuthorization == .reducedAccuracy {
            showAlert(reason: "정확한 위치 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
        }
        
        requestActivityAuthorization()
    }
}

extension AerobicActivityViewController {
    private func requestLocationAuthorization() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest // 정확도 설정
            locationManager!.requestWhenInUseAuthorization() // 포그라운드 위치 추적
            
            // 필요한가?
            locationManager?.requestAlwaysAuthorization() // 백그라운드 위치 추적

            locationManager?.allowsBackgroundLocationUpdates = true
            locationManager?.pausesLocationUpdatesAutomatically = false
            
//            locationManager?.distanceFilter = 5 // 5m 마다 위치 업데이트

            locationManager!.delegate = self
            locationManagerDidChangeAuthorization(locationManager!) // 권한 변경 확인
        } else {
            //사용자의 위치가 바뀌고 있는지 확인하는 메소드
            locationManager!.startMonitoringSignificantLocationChanges()
        }
    }
    
    private func requestActivityAuthorization() {
        if motionManager == nil { // 처음 시작할 때
            motionManager = CMMotionActivityManager()
            return
        }
        
        switch CMMotionActivityManager.authorizationStatus() {
        case CMAuthorizationStatus.authorized:
            return
    
        case CMAuthorizationStatus.denied:
            showAlert(reason: "동작 및 피트니스 요청 거부됨", discription: "피트니스 추적을 할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안 > 동작 및 피트니스'에서 피트니스 추적을 켜주세요.(필수권한)")
            
        default:
            showAlert(reason: "동작 및 피트니스 요청 거부됨", discription: "피트니스 추적을 할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안 > 동작 및 피트니스'에서 피트니스 추적을 켜주세요.(필수권한)")
        }
    }
}

extension AerobicActivityViewController {
    
    func startActivity() {
        requestActivityAuthorization()
        
        motionManager?.startActivityUpdates(to: .main) { activity in
            guard let activity = activity else {
                return
            }
            
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(timeInterval: self.interval, target: self, selector: #selector(self.timerCounter), userInfo: nil, repeats: true)
            }
            
            let currentSpeed = self.locationManager?.location?.speed // m/s
            switch self.exerciseLabel.text {
                
            case "러닝":
                if activity.stationary == true {
                    self.locationManager?.stopUpdatingLocation()
                    self.state.text = "상태: 정지"
                    self.updateLabelText(speed: 0)
                }
                else if (activity.walking == true || activity.running == true) {
                    if activity.stationary == false {
                        self.locationManager?.startUpdatingLocation()
                        self.state.text = "상태: 러닝 중"
                        print("====> \(activity)")
                    }
                    else { // !!! 상태는 상호 독립적인 것이 아니다.
                        self.locationManager?.stopUpdatingLocation()
                        self.state.text = "상태: 러닝 중 정지"
                        self.updateLabelText(speed: 0)
                    }
                }
                else if (activity.cycling == true || activity.automotive == true) {
                    self.motionManager?.stopActivityUpdates()
                    self.locationManager?.stopUpdatingLocation()
                    self.timer?.invalidate()
                    self.state.text = "상태: 이동수단"
                    self.showAlert()
                    }
                    // CMMotionActivity @ 21432.287857,<startDate,2022-12-01 16:00:59 +0000,confidence,2,unknown,0,stationary,0,walking,0,running,0,automotive,0,cycling,0>
                    // 이런식으로 아무것도 아닌 경우도 생긴다.
                else { // activity.unknown || 전부 0인 상태
                    
                    // 실제로 어떤 상태인지 모르기 때문에 일단은 위치 업데이트를 시키지만 러닝이 아닌 경우
                    self.locationManager?.startUpdatingLocation()
                    
                    self.state.text = "상태: unknown"
                    let speed = Double(currentSpeed ?? 0)
                    
                    // -------> 여기도 didUpdateLocations에서 처리 가능
                    if speed > 11.111 { // 약 40km/h 초과
                        self.motionManager?.stopActivityUpdates()
                        self.locationManager?.stopUpdatingLocation()
                        self.timer?.invalidate()
                        self.state.text = "상태: unknown, 속도 오버"
                        self.showAlert()
                    }
                    
//                    if speed <= 0.8333 { // 약 3km/h - 정지라고 판단
//                        // ---------------> 여기서 에러 / 여기 들어오면 unknwon에서 다음 속도는 계속 0
//                        self.locationManager?.startUpdatingLocation()
////                        self.locationManager?.stopUpdatingLocation()
//                        self.state.text = "상태: unknown 정지판단"
//                        self.updateLabelText(speed: 0)
//                        print("-------->: \(activity)")
//                    }
//                    else if speed <= 11.111 { // 약 40km/h 이하
////                        self.locationManager?.stopUpdatingLocation()
//                        self.locationManager?.startUpdatingLocation()
//                        print("-------->: \(activity)")
//                    }
//                    else { // 약 40km/h 초과
//                        self.motionManager?.stopActivityUpdates()
//                        self.locationManager?.stopUpdatingLocation()
//                        self.timer?.invalidate()
//                        self.state.text = "상태: unknown, 속도 오버"
//                        self.showAlert()
//                    }
                }
                
            case "싸이클":
                if activity.stationary == true {
                    self.locationManager?.stopUpdatingLocation()
                    self.state.text = "상태: 정지"
                    self.updateLabelText(speed: 0)
                }
                if activity.cycling == true {
                    if activity.stationary == false {
                        self.locationManager?.startUpdatingLocation()
                        self.state.text = "상태: 싸이클 중"
                    }
                    else {
                        self.locationManager?.stopUpdatingLocation()
                        self.state.text = "상태: 싸이클 중 정지"
                        self.updateLabelText(speed: 0)
                    }
                }
                else if activity.automotive == true {
                    self.motionManager?.stopActivityUpdates()
                    self.locationManager?.stopUpdatingLocation()
                    self.timer?.invalidate()
                    self.state.text = "상태: 이동수단"
                    self.showAlert()
                }
                else { // walking, running, unknown
                    self.state.text = "상태: unknown"
                    let speed = Double(currentSpeed ?? 0)
                    
                    if speed <= 0.8333 {
                        self.locationManager?.stopUpdatingLocation()
                        self.updateLabelText(speed: 0)
                        print("-------->: \(activity)")
                    }
                    else if speed <= 13.888 { // 약 50km/h
//                        self.locationManager?.stopUpdatingLocation()
                        self.locationManager?.startUpdatingLocation()
                        print("-------->: \(activity)")
                    }
                    else { // 약 50km/h 이상
                        self.motionManager?.stopActivityUpdates()
                        self.locationManager?.stopUpdatingLocation()
                        self.timer?.invalidate()
                        self.state.text = "상태: 이동수단"
                        self.showAlert()
                    }
                }
                
            default:
                return
            }
        }
    }
    
    func showAlert() {
        let alert = UIAlertController(title:"경고", message: "이동수단 사용", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .destructive) { _ in
//            self.TTSstart(input: "운동을 종료합니다.")
            self.motionManager?.stopActivityUpdates()
            self.locationManager?.stopUpdatingLocation()
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert,animated: true,completion: nil)
    }
    
    func showAlert(reason: String, discription: String) {
        let alert = UIAlertController(title: reason, message: discription, preferredStyle: .alert)
        let ok = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            // 설정으로 이동
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        let cancle = UIAlertAction(title: "취소", style: .default, handler: nil)
        // 색상 적용.
        cancle.setValue(UIColor.darkGray, forKey: "titleTextColor")
        alert.addAction(cancle)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

extension AerobicActivityViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        switch status {
        case .authorizedAlways, .authorizedWhenInUse: // GPS 권한 설정됨
            self.mapView.showsUserLocation = true
            self.mapView.setUserTrackingMode(.follow, animated: true)
            
            startActivity() // permission true -> start activity
            
        case .restricted, .notDetermined: // GPS 권한 미설정
            requestLocationAuthorization()
            
        case .denied: // GPS 권한 거부됨
            showAlert(reason: "GPS 권한 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
            
        default:
            requestLocationAuthorization()
        }

        if manager.accuracyAuthorization == .reducedAccuracy {
            showAlert(reason: "정확한 위치 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last // 가장 최근 위치
        else { return }
        
        let latitude = location.coordinate.latitude
        let longtitude = location.coordinate.longitude
       
        if let prevLocation = self.previousLocation {
            
            // 5m 마다 업데이트하면 거리는 무조건 5m단위?
            let prevCoordinate = prevLocation.coordinate
            var points: [CLLocationCoordinate2D] = []
            let point1 = CLLocationCoordinate2DMake(prevCoordinate.latitude, prevCoordinate.longitude) // previous Coordinate
            let point2: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longtitude) // current Coordinate
            
            points.append(point1)
            points.append(point2)
            
            let pTOp_Distance = Double(calcDistance(from: point1, to: point2)) // PtoP_distance: 미터(m), useTime: 초(s)
            exerciseSequence(PtoP_distance: pTOp_Distance)
            
            
            // ------------> edit 분기
            
            let speed = Double(manager.location?.speed ?? 0) // m/s
            
            if speed <= 0.8333 { // 약 3km/h 이하
                self.state.text = "상태: 속도 3 이하"
                return
            } else { // 약 3km/h 초과일 때만 지도에 경로 그리기
                // draw
                let lineDraw = MKPolyline(coordinates: points, count:points.count)
                self.mapView.addOverlay(lineDraw)
            }
            
            // 달리기때 약 40km/h 초과시 강제종료 조건문 추가
        }
        self.previousLocation = location
    }
    
    func calcDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    func exerciseSequence(PtoP_distance: Double) {
        var Speed: Double = locationManager?.location?.speed ?? 0
//        totalDistance += PtoP_distance
        
        if Speed <= 0 {
            Speed = 0
        } else {
            totalDistance += PtoP_distance
        }
        
        updateLabelText(speed: Speed)
    }
    
    func updateLabelText(speed: Double) {
        self.moveDistance.text = "이동거리: " + String(format: "%.2f", totalDistance * 0.001) + "km"
        if speed == 0 {
            self.currentSpeed.text = "속도: 0km/h"
        } else {
            self.currentSpeed.text = "속도: " + String(format: "%.2f", speed * 3.6) + "km/h"
        }
    }
}

extension AerobicActivityViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyLine = overlay as? MKPolyline else {
            print("can't draw polyline")
            return MKOverlayRenderer()
        }
        let renderer = MKPolylineRenderer(polyline: polyLine)
        renderer.strokeColor = .orange
        renderer.lineWidth = 5.0
        renderer.alpha = 1.0
        
        return renderer
    }
}

extension AerobicActivityViewController {
    @objc func timerCounter() -> Void {
        count += 1
        let time = secondsToHourMinutesSecond(seconds: count)
        let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
        timeLabel.text = timeString
    }
    
    func secondsToHourMinutesSecond(seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func makeTimeString(hours: Int, minutes: Int, seconds: Int) -> String {
        
        var timeString = ""
        timeString += String(format: "%02d", hours)
        timeString += " : "
        timeString += String(format: "%02d", minutes)
        timeString += " : "
        timeString += String(format: "%02d", seconds)
        
        return timeString
    }
    
    func configure() {
        guard let info = viewModel.ExerciseInfo as? aerobicExerciseInfo else {
            return
        }
        exerciseLabel.text = info.exercise
        goalDistance.text = "\(info.distance)"
        goalTime.text = "\(info.time)"
    }
}
