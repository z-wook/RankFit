//
//  AnaerobicActivityViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit

class AnaerobicActivityViewController: UIViewController {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setLabel: UILabel!
    @IBOutlet weak var setNumLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var weightNumLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var countNumLabel: UILabel!
    @IBOutlet weak var set_leading: NSLayoutConstraint!
    @IBOutlet weak var count_trailing: NSLayoutConstraint!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var viewModel: DoExerciseViewModel!
    var timer: Timer?
    let interval: Double = 1.0
    var count: Int = 0
    var timerCounting: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    
    func configure() {
        guard let info = viewModel.ExerciseInfo as? anaerobicExerciseInfo else {
            return
        }
        exerciseLabel.text = info.exercise
        setNumLabel.text = "\(info.set)"
        weightNumLabel.text = "\(info.weight)"
        countNumLabel.text = "\(info.count)"
        if info.weight == 0 {
            weightLabel.isHidden = true
            weightNumLabel.isHidden = true
            
            set_leading.constant = 100
            count_trailing.constant = 100
        }
    }
    
    @IBAction func pauseAndPlay(_ sender: UIButton) {
        timerCounting.toggle()
        
        if timerCounting {
            playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        } else {
            playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            timer?.invalidate()
        }
    }
    
    @IBAction func stopActivity(_ sender: UIButton) {
        timerCounting = false
        playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        timer?.invalidate()
        
        showAlert()
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "운동을 종료하시겠습니까?", message: "기록이 저장됩니다.", preferredStyle: UIAlertController.Style.alert)
        let cancle = UIAlertAction(title: "취소", style: .destructive, handler: nil)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            
            guard let info = self.viewModel.ExerciseInfo as? anaerobicExerciseInfo else {
                return
            }
            let update = ConfigDataStore.updateCoreData(id: info.id, entityName: "Anaerobic", done: true)
            
            if update == true {
                print("운동 완료")
                // reload
                
            } else { return }
            
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(cancle)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension AnaerobicActivityViewController {
    
    @objc func timerCounter() {
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
}
