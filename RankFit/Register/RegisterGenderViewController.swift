//
//  RegisterGenderViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/12.
//

import UIKit

class RegisterGenderViewController: UIViewController {

    @IBOutlet weak var genderPickerView: UIPickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    var infomation: userInfo!
    let gender: [String] = ["남성", "여성"] // 남성 0, 여성 1
    var pickGender: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonConfigure()
        pickerViewConfigure()
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func buttonConfigure() {
        nextButton.layer.cornerRadius = 20
        nextButton.layer.shadowColor = UIColor.gray.cgColor
        nextButton.layer.shadowOpacity = 1.0
        nextButton.layer.shadowOffset = CGSize.zero
        nextButton.layer.shadowRadius = 7
    }
    
    private func pickerViewConfigure() {
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        let defaultRow: Int = 0
        genderPickerView.selectRow(defaultRow, inComponent: 0, animated: true)
        pickGender = defaultRow
    }

    @IBAction func gotoAgeVC(_ sender: UIButton) {
        self.infomation = userInfo(gender: pickGender)
        
        let sb = UIStoryboard(name: "Register", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "RegisterAgeViewController") as! RegisterAgeViewController
        vc.infomation = self.infomation
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegisterGenderViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // pickerView에 담긴 아이템의 컴포넌트 개수
    // pickerView는 여러 개의 wheel이 있을 수 있다.
    // 여기서는 1개의 wheel을 가진 pickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return gender.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickGender = row
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: gender[row], attributes: [.foregroundColor:UIColor.label])
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
}
