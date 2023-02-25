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
    
    var infomation: userInfo!
    var weight: [String] = []
    var pickWeight: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addWeight()
        buttonConfigure()
        pickerViewConfigure()
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func addWeight() {
        for i in 35...150 {
            weight.append("\(i)")
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
        weightPickerView.delegate = self
        weightPickerView.dataSource = self
        // pickerView 초기값 세팅
        let defaultRow = 25
        weightPickerView.selectRow(defaultRow, inComponent: 0, animated: true)
        pickWeight = weight[defaultRow]
    }
    
    @IBAction func gotoNext(_ sender: UIButton) {
        let IntWeight = Int(pickWeight) ?? 0
        self.infomation = userInfo(gender: infomation.gender, birth: infomation.birth, weight: IntWeight)
        let sb = UIStoryboard(name: "Register", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "RegisterAccountViewController") as! RegisterAccountViewController
        vc.infomation = self.infomation
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegisterWeightViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return weight.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: weight[row] + "kg", attributes: [.foregroundColor:UIColor.label])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickWeight = weight[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(40)
    }
}
