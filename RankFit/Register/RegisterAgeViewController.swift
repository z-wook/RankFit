//
//  RegisterAgeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/12.
//

import UIKit

class RegisterAgeViewController: UIViewController {

    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet weak var nextButton: UIButton!
    
    var information: userInfo!
    let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backButtonDisplayMode = .minimal
        formatter.dateFormat = "yyyy-MM-dd"        
        buttonConfigure()
        pickerViewConfigure()
    }

    private func pickerViewConfigure() {
        datePickerView.maximumDate = Date()
    }
    
    private func buttonConfigure() {
        nextButton.layer.cornerRadius = 20
        nextButton.layer.shadowColor = UIColor.gray.cgColor
        nextButton.layer.shadowOpacity = 1.0
        nextButton.layer.shadowOffset = CGSize.zero
        nextButton.layer.shadowRadius = 7
    }
    
    @IBAction func gotoWeightVC(_ sender: UIButton) {
        let date = formatter.string(from: datePickerView.date)
        self.information = userInfo(gender: information.gender, birth: date)
        let sb = UIStoryboard(name: "Register", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "RegisterWeightViewController") as! RegisterWeightViewController
        vc.information = self.information
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
