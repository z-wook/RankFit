//
//  RegisterAgeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/12.
//

import UIKit

class RegisterAgeViewController: UIViewController {

    @IBOutlet weak var agePickerView: UIPickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    var viewModel: userInfo!
    var age: [String] = []
    var pickAge: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addAge()
        buttonConfigure()
        pickerViewConfigure()
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func addAge() {
        for i in 10...100 {
            age.append("\(i)")
        }
    }

    private func buttonConfigure() {
        nextButton.layer.cornerRadius = 20
        nextButton.layer.shadowColor = UIColor.gray.cgColor
        nextButton.layer.shadowOpacity = 1.0
        nextButton.layer.shadowOffset = CGSize.zero
        nextButton.layer.shadowRadius = 7
    }
    
    private func pickerViewConfigure() {
        agePickerView.delegate = self
        agePickerView.dataSource = self
        // pickerView 초기값 세팅
        let defaultRow = 15
        agePickerView.selectRow(defaultRow, inComponent: 0, animated: true)
        pickAge = age[defaultRow]
    }
    
    @IBAction func gotoWeightVC(_ sender: UIButton) {
        let IntAge = Int(pickAge) ?? 0
        if (IntAge >= 10 && IntAge <= 100) {
            self.viewModel = userInfo(gender: viewModel.gender, age: IntAge)
            let sb = UIStoryboard(name: "Register", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "RegisterWeightViewController") as! RegisterWeightViewController
            vc.viewModel = self.viewModel
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("========> 다시 선택하기")
        }
    }
}

extension RegisterAgeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    // wheel 개수
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return age.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickAge = age[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: age[row] + "세", attributes: [.foregroundColor:UIColor.label])
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
}
