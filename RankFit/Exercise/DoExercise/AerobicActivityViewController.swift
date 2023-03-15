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
import Combine
import AVFoundation

class AerobicActivityViewController: UIViewController {
    
    @IBOutlet weak var goalDistance: UILabel!
    @IBOutlet weak var goalTime: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var moveDistance: UILabel!
    @IBOutlet weak var currentSpeed: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var altitude: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let sendState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var exerciseInfo: aerobicExerciseInfo!
    var viewModel: DoExerciseViewModel!
    let center = NotificationCenter.default
    var motionManager: CMMotionActivityManager?
    var locationManager: CLLocationManager?
    var previousLocation: CLLocation? // 이전 위치 정보 저장
    var totalDistance: Double = 0 // 실제 움직인 거리 m
    var maxSpeed: Double = 0
    var avgSpeed: Double = 0
    var timer: Timer?
    var count = 0
    var saveTime: Int64!
    var backgroundTime: Date? // Background로 진입한 시간
    var soundEffect: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        requestLocationAuthorization() // location config & permission
        bind()
        prepareAnimation()
        showAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
        motionManager?.stopActivityUpdates()
        locationManager?.stopUpdatingLocation()
        center.removeObserver(self)
    }
    
    @IBAction func currentLocationBtn(_ sender: UIButton) {
        let status = locationManager?.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            
        default:
            showAlert(reason: "GPS 권한 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
        }
        if locationManager?.accuracyAuthorization == .reducedAccuracy {
            showAlert(reason: "정확한 위치 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
        }
        requestActivityAuthorization()
    }
    
    @IBAction func saveExercise(_ sender: UIButton) {
        if (exerciseInfo.distance <= totalDistance * 0.001) { // 거리 달성
            exDoneAlert()
        } else { // 거리 미달성
            exCancelAlert()
        }
    }
}

extension AerobicActivityViewController {
    private func startActivity() {
        requestActivityAuthorization()
        
        motionManager?.startActivityUpdates(to: .main) { activity in
            guard let activity = activity else { return }
            if self.timer == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.timer = self.initTimer()
                }
            }
            let currentSpeed = self.locationManager?.location?.speed // m/s
            let speed = Double(currentSpeed ?? 0)
            if self.maxSpeed < speed {
                self.maxSpeed = speed
                self.maxSpeedLabel.text = "최고속도: " + String(format: "%.2f", self.maxSpeed * 3.6) + "km/h"
            }
            switch self.exerciseInfo.exercise {
            case "러닝":
                if activity.stationary == true {
                    self.locationManager?.stopUpdatingLocation()
                    self.updateLabelText(speed: 0)
                } else if (activity.walking == true || activity.running == true) {
                    if activity.stationary == false {
                        self.locationManager?.startUpdatingLocation()
                        // walking || running이면서 약 38km/h 초과시 강제종료
                        if speed > 10.555 { // 약 38km/h 초과
                            self.showAlert(activity: "activity.stationary", speed: speed)
                            return
                        }
                    } else { // !!! 상태는 상호 독립적인 것이 아니다.
                        self.locationManager?.stopUpdatingLocation()
                        self.updateLabelText(speed: 0)
                    }
                } else if (activity.cycling == true || activity.automotive == true) {
                    self.showAlert(activity: "cycling, automotive", speed: speed)
                    return
                }
                // CMMotionActivity @ 21432.287857,<startDate,2022-12-01 16:00:59 +0000,confidence,2,unknown,0,stationary,0,walking,0,running,0,automotive,0,cycling,0>
                // 이런식으로 아무것도 아닌 경우도 생긴다.
                else { // activity.unknown || 전부 0인 상태
                    // 실제로 어떤 상태인지 모르기 때문에 일단은 위치 업데이트를 시키지만 러닝이 아닌 경우
                    self.locationManager?.startUpdatingLocation()
                    // unknown이면서 약 38km/h 초과시 강제종료
                    if speed > 10.555 { // 약 38km/h 초과
                        self.showAlert(activity: "activity.unknown", speed: speed)
                        return
                    }
                }
                
            case "싸이클":
                if activity.stationary == true {
                    self.locationManager?.stopUpdatingLocation()
                    self.updateLabelText(speed: 0)
                }
                if activity.cycling == true {
                    if activity.stationary == false {
                        self.locationManager?.startUpdatingLocation()
                    } else {
                        self.locationManager?.stopUpdatingLocation()
                        self.updateLabelText(speed: 0)
                    }
                } else if activity.automotive == true {
                    self.motionManager?.stopActivityUpdates()
                    self.locationManager?.stopUpdatingLocation()
                    self.timer?.invalidate()
                    self.showAlert(activity: "activity.automotive", speed: speed)
                    return
                } else { // walking, running, unknown
                    self.locationManager?.startUpdatingLocation()
                    // unknown이면서 약 50km/h 초과시 강제종료
                    if speed > 13.888 {
                        self.showAlert(activity: "walking, running, unknown", speed: speed)
                        return
                    }
                }
                
            default:
                return
            }
        }
    }
}

extension AerobicActivityViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: // GPS 권한 설정됨
            mapView.delegate = self
            mapView.isZoomEnabled = true
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            startActivity() // permission true -> start activity
            
        case .restricted, .notDetermined: // GPS 권한 미설정
            requestLocationAuthorization()
            
        case .denied: // GPS 권한 거부됨
            showAlert(reason: "GPS 권한 요청 거부됨", discription: "위치 서비스를 사용할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안'에서 위치 서비스를 켜주세요.(필수권한)")
            return
            
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
        altitude.text = "고도: " + String(format: "%.2f", location.altitude) + "m"
        let latitude = location.coordinate.latitude
        let longtitude = location.coordinate.longitude
        if let prevLocation = self.previousLocation {
            let prevCoordinate = prevLocation.coordinate
            var points: [CLLocationCoordinate2D] = []
            let point1 = CLLocationCoordinate2DMake(prevCoordinate.latitude, prevCoordinate.longitude) // previous Coordinate
            let point2: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longtitude) // current Coordinate
            points.append(point1)
            points.append(point2)
            let pTOp_Distance = Double(calcDistance(from: point1, to: point2)) // PtoP_distance: 미터(m), useTime: 초(s)
            let speed = Double(manager.location?.speed ?? 0) // m/s
            if speed < 0.6944 { // 약 2.5km/h 미만일 때 정지라고 판단
                self.updateLabelText(speed: 0)
                return
            }
            exerciseSequence(PtoP_distance: pTOp_Distance, Points: points, Counts: points.count)
        }
        self.previousLocation = location
    }
    
    func calcDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    func exerciseSequence(PtoP_distance: Double, Points: [CLLocationCoordinate2D], Counts: Int) {
        let Speed: Double = locationManager?.location?.speed ?? 0
        totalDistance += PtoP_distance
        // draw
        let lineDraw = MKPolyline(coordinates: Points, count: Counts)
        self.mapView.addOverlay(lineDraw)
        // update Label
        updateLabelText(speed: Speed)
    }
    
    private func updateLabelText(speed: Double) {
        self.moveDistance.text = "이동거리: " + String(format: "%.2f", totalDistance * 0.001) + "km"
        if speed <= 0 {
            self.currentSpeed.text = "속도: 0km/h"
        } else {
            self.currentSpeed.text = "속도: " + String(format: "%.2f", speed * 3.6) + "km/h"
        }
    }
}

extension AerobicActivityViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyLine = overlay as? MKPolyline else {
            print("Can't Draw Polyline")
            configFirebase.errorReport(type: "AerobicActivityVC.mapView", descriptions: "Can't Draw Polyline")
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
    private func bind() {
        sendState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result { 
                print("서버 운동 업데이트 성공")
                // CoreData 저장 단위가(분)이기 때문에 (분)으로 맞추는것으로 통일, int16형
                let doubleCount = Double(self.count)
                var countToMin = Int16(round(doubleCount / 60)) // minute
                if countToMin < 1 {
                    countToMin = 1
                }
                let update = ExerciseCoreData.updateCoreData(id: self.exerciseInfo.id, entityName: "Aerobic", distance: self.totalDistance * 0.001, time: countToMin, saveTime: self.saveTime, done: true)
                if update {
                    print("운동 완료 후 업데이트 성공")
                    configFirebase.saveDoneEx(exName: self.exerciseInfo.exercise, set: 0, weight: 0, count: 0, distance: self.totalDistance, maxSpeed: self.maxSpeed * 3.6, avgSpeed: self.avgSpeed * 3.6, time: Int64(self.count), date: self.exerciseInfo.date)
                    ExerciseViewController.reloadEx.send(true)
                    self.navigationController?.popViewController(animated: true)
                } else {
                    print("운동 완료 후 업데이트 실패")
                    self.showError()
                    return
                }
            } else { // 서버 전송 실패
                print("서버 전송 오류, 잠시 후 다시 시도해 주세요.")
                self.showError()
            }
        }.store(in: &subscriptions)
    }
    
    private func configure() {
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        guard let info = viewModel.ExerciseInfo as? aerobicExerciseInfo else { return }
        exerciseInfo = info
        goalDistance.text = "목표 거리: \(info.distance)km"
        goalTime.text = "목표 시간: \(info.time)분"
        let soundEffect = UserDefaults.standard.integer(forKey: "sound")
        if soundEffect == 0 { playAudio() }
        
        center.addObserver(self, selector: #selector(enterForeground), name: NSNotification.Name("WillEnterForeground"), object: nil)
        center.addObserver(self, selector: #selector(enterBackground), name: NSNotification.Name("DidEnterBackground"), object: nil)
    }
    
    @objc func enterForeground(notification: NSNotification) {
        let foregroundTime = Date()
        guard let backgroundTime = backgroundTime else { return }
        let interval = TimeStamp.getTimeInterval(now: foregroundTime, before: backgroundTime)
        count += Int(interval)
        let time = secondsToHourMinutesSecond(seconds: count)
        let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
        timeLabel.text = timeString
        timer = initTimer()
    }
    
    @objc func enterBackground(notification: NSNotification) {
        // 타이머 작동중이라면 정지 시키고 백그라운드 함수 실행
        if timer?.isValid == true {
            timer?.invalidate()
            backgroundTime = Date()
        } else { // 타이머 정지 상태라면 패스
            backgroundTime = nil
        }
    }
    
    private func playAudio() {
        let url = Bundle.main.url(forResource: "Running", withExtension: "mp3")
        if let url = url {
            do {
                soundEffect = try AVAudioPlayer(contentsOf: url)
                guard let sound = soundEffect else { return }
                sound.prepareToPlay()
                sound.volume = 0.5
                sound.play()
            } catch let error {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    private func prepareAnimation() {
        timeLabel.transform = CGAffineTransform(translationX: view.bounds.width, y: 0).scaledBy(x: 3, y: 3).rotated(by: 180)
        timeLabel.alpha = 0
    }
    
    private func showAnimation() {
        UIView.animate(withDuration: 1, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 2, options: .allowUserInteraction, animations: {
            self.timeLabel.transform = CGAffineTransform.identity
            self.timeLabel.alpha = 1
        }, completion: nil)
    }
}

extension AerobicActivityViewController {
    private func showAlert(activity: String, speed: Double) {
        let alert = UIAlertController(title: "비정상적인 움직임 감지", message: "측정 중 비정상적인 움직임이 감지되어 운동을 종료합니다.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .destructive) { _ in
            let speed = String(format: "%.2f", speed * 3.6) + "km/h"
            configFirebase.reportAutomotive(type: activity, speed: speed)
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert,animated: true,completion: nil)
    }
    
    private func showAlert(reason: String, discription: String) {
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
    
    private func exDoneAlert() {
        let alert = UIAlertController(title: "운동을 종료하시겠습니까?", message: "기록이 저장됩니다.", preferredStyle: UIAlertController.Style.alert)
        let cancle = UIAlertAction(title: "취소", style: .destructive, handler: nil)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            // CoreData 저장 단위가(분)이기 때문에 (분)으로 맞추는것으로 통일, int형
            let doubleCount = Double(self.count)
            var countToMin = Int(round(doubleCount / 60)) // minute
            if countToMin < 1 {
                countToMin = 1
            }
            let time = Int64(TimeStamp.getCurrentTimestamp())
            self.saveTime = time
            configServer.sendCompleteEx(info: self.exerciseInfo, totalDis: self.totalDistance * 0.001, time: countToMin, saveTime: time, subject: self.sendState)
        }
        alert.addAction(cancle)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func exCancelAlert() {
        let alert = UIAlertController(title: "운동을 종료하시겠습니까?", message: "목표에 도달하지 못하여 기록이 저장되지 않습니다.", preferredStyle: UIAlertController.Style.alert)
        let cancle = UIAlertAction(title: "취소", style: .destructive, handler: nil)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(cancle)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func showError() {
        let alert = UIAlertController(title: "서버와 통신 오류", message: "잠시 후 다시 시도해 주세요.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension AerobicActivityViewController {
    private func requestLocationAuthorization() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest // 정확도 설정
            locationManager!.requestWhenInUseAuthorization() // 포그라운드 위치 추적
            locationManager?.requestAlwaysAuthorization() // 백그라운드 위치 추적
            locationManager?.allowsBackgroundLocationUpdates = true
            locationManager?.pausesLocationUpdatesAutomatically = false
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
        case CMAuthorizationStatus.authorized: return
            
        default:
            showAlert(reason: "동작 및 피트니스 요청 거부됨", discription: "피트니스 추적을 할 수 없습니다. 기기의 '설정 > 개인정보 보호 및 보안 > 동작 및 피트니스'에서 피트니스 추적을 켜주세요.(필수권한)")
        }
    }
}

extension AerobicActivityViewController {
    private func initTimer() -> Timer {
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        return timer
    }
    
    @objc func timerCounter() {
        count += 1
        let time = secondsToHourMinutesSecond(seconds: count)
        let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
        timeLabel.text = timeString
    }
    
    private func secondsToHourMinutesSecond(seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    private func makeTimeString(hours: Int, minutes: Int, seconds: Int) -> String {
        var timeString = ""
        timeString += String(format: "%02d", hours)
        timeString += " : "
        timeString += String(format: "%02d", minutes)
        timeString += " : "
        timeString += String(format: "%02d", seconds)
        return timeString
    }
}
