//
//  ChangeWeightViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/17.
//

import UIKit
import Combine

class ChangeWeightViewController: UIViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let viewModel = InputInfoViewModel()
    let userInfo = getSavedDateInfo()
    let fireState = PassthroughSubject<Bool, Never>()
    let serverState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var list: [String] = []
    var pickElement: String!
    var intWeight: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configPickerView()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isUserInteractionEnabled = true
    }
    
    private func bind() {
        fireState.receive(on: RunLoop.main).sink { result in
            if result {
                self.viewModel.sendWeightToServer(newWeight: self.intWeight, subject: self.serverState)
            } else {
                self.indicator.stopAnimating()
                self.showAlert()
            }
        }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result {
                SettingViewController.reloadProfile.send(true)
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.showAlert()
            }
        }.store(in: &subscriptions)
    }
    
    private func configure() {
        saveBtn.layer.cornerRadius = 20
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
    }
    
    private func configPickerView() {
        // pickerView 초기값 세팅
        pickerView.delegate = self
        pickerView.dataSource = self
        var defaultRow: Int!
        
        self.navigationItem.title = "몸무게 설정"
        descriptionLabel.text = "변경할 몸무게를 입력해 주세요."
        for i in 35...150 {
            list.append("\(i)")
        }
        let weight = saveUserData.getKeychainIntValue(forKey: .Weight) ?? 100
        defaultRow = weight - 35
        pickerView.selectRow(defaultRow, inComponent: 0, animated: true)
        pickElement = list[defaultRow]
        
        let day = userInfo.getWeightDate()
        if (calcDate().currentDate() >= day && day != "-1") {
            // 몸무게 변경 가능
            messageLabel.layer.isHidden = true
            saveBtn.isEnabled = true
        } else {
            messageLabel.text = "몸무게 변경 후 하루가 지나지 않아 현재 닉네임을 변경할 수 없습니다."
            saveBtn.isEnabled = false
            saveBtn.backgroundColor = .darkGray
        }
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        backgroundView.isHidden = false
        indicator.startAnimating()
        self.tabBarController?.tabBar.isUserInteractionEnabled = false
        intWeight = Int(pickElement) ?? 1
        configFirebase.updateWeight(weight: intWeight, subject: fireState)
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "몸무게 변경 오류", message: "잠시 후 다시 시도해 주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ChangeWeightViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // pickerView에 담긴 아이템의 컴포넌트 개수
    // pickerView는 여러 개의 wheel이 있을 수 있다.
    // 여기서는 1개의 wheel을 가진 pickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickElement = list[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: list[row] + "kg", attributes: [.foregroundColor:UIColor.label])
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
}
