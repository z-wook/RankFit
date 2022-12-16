//
//  RegisterWeightViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/12.
//

import UIKit

class RegisterWeightViewController: UIViewController {

    @IBOutlet weak var weightPickerView: UIPickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    var weight: [String] = []
    var pickWeight: String!
    var viewModel: userInfo!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addWeight()
        buttonConfigure()
        pickerViewConfigure()
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func addWeight() {
        for i in 40...150 {
            weight.append("\(i)")
        }
    }
    
    private func buttonConfigure() {
        nextButton.layer.cornerRadius = 20
    }
    
    private func pickerViewConfigure() {
        weightPickerView.delegate = self
        weightPickerView.dataSource = self
        // pickerView 초기값 세팅
        let defaultRow = 20
        weightPickerView.selectRow(defaultRow, inComponent: 0, animated: true)
        pickWeight = weight[defaultRow]
    }
    
    @IBAction func gotoNext(_ sender: UIButton) {
        let IntWeight = Int(pickWeight) ?? 0
        if (IntWeight >= 40 && IntWeight <= 150) {
            self.viewModel = userInfo(gender: viewModel.gender, age: viewModel.age, weight: IntWeight)
            let sb = UIStoryboard(name: "Register", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
            vc.info = self.viewModel
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("========> 다시 선택하기")
        }
    }
}

extension RegisterWeightViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // wheel 2개 / 정수부분, 실수부분
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return weight.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: weight[row] + "kg", attributes: [.foregroundColor:UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickWeight = weight[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
}
