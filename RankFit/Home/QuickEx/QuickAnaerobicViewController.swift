//
//  QuickExViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/28.
//

import UIKit

class QuickAnaerobicViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var timer: Timer?
    var count: Int = 0
    var timerCounting: Bool = true
    var backgroundTime: Date? // Background로 진입한 시간
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        prepareAnimation()
        showAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timer = self.initTimer()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func pauseAndPlay(_ sender: UIButton) {
        timerCounting.toggle()
        
        if timerCounting {
            playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            timer = initTimer()
        } else {
            playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            timer?.invalidate()
        }
    }
    
    @IBAction func stopActivity(_ sender: UIButton) {
        timerCounting = false
        playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        timer?.invalidate()
//        if count < 60 { // 1분 미만의 운동은 제외하기
//            showExAlert()
//            return
//        }
        showAlert(title: "운동을 종료하시겠습니까?", message: "기록이 저장됩니다.")
    }
}

extension QuickAnaerobicViewController {
    private func configure() {
        navigationItem.backButtonDisplayMode = .minimal
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(enterForeground), name: NSNotification.Name("WillEnterForeground"), object: nil)
        
        center.addObserver(self, selector: #selector(enterBackground), name: NSNotification.Name("DidEnterBackground"), object: nil)
    }
    
    @objc func enterForeground() {
        let foregroundTime = Date()
        guard let backgroundTime = backgroundTime else { return }
        let interval = TimeStamp.getTimeInterval(now: foregroundTime, before: backgroundTime)
        count += interval
        let time = secondsToHourMinutesSecond(seconds: count)
        let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
        timeLabel.text = timeString
        timer = initTimer()
    }
    
    @objc func enterBackground() {
        // 타이머 작동중이라면 정지 시키고 백그라운드 함수 실행
        if timer?.isValid == true {
            timer?.invalidate()
            backgroundTime = Date()
        } else { // 타이머 정지 상태라면 패스
            backgroundTime = nil
        }
    }
    
    private func prepareAnimation() {
        titleLabel.transform = CGAffineTransform(translationX: view.bounds.width, y: 0).scaledBy(x: 3, y: 3).rotated(by: 180)
        timeLabel.transform = CGAffineTransform(translationX: view.bounds.width, y: 0).scaledBy(x: 3, y: 3).rotated(by: 180)
        titleLabel.alpha = 0
        timeLabel.alpha = 0
    }
    
    private func showAnimation() {
        UIView.animate(withDuration: 1, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 2, options: .allowUserInteraction, animations: {
            self.titleLabel.transform = CGAffineTransform.identity
            self.titleLabel.alpha = 1
        }, completion: nil)
        
        UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.6, initialSpringVelocity: 2, options: .allowUserInteraction, animations: {
            self.timeLabel.transform = CGAffineTransform.identity
            self.timeLabel.alpha = 1
        }, completion: nil)
    }
}

extension QuickAnaerobicViewController {
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let cancle = UIAlertAction(title: "취소", style: .destructive, handler: nil)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "QuickSaveViewController") as! QuickSaveViewController
            vc.count = self.count
            self.navigationController?.pushViewController(vc, animated: true)
        }
        alert.addAction(cancle)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func showExAlert() {
        let alert = UIAlertController(title: "운동 시간 부족", message: "올바른 운동을 위해 일정 시간 운동을 해주세요.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension QuickAnaerobicViewController {
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
