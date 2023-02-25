//
//  ChoiceWayViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/29.
//

import UIKit

class ChoiceWayViewController: UIViewController {
    
    @IBOutlet weak var buttonView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    private func configure() {
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
        buttonView.layer.cornerRadius = 10
    }
    
    @IBAction func goRegister(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegisterGenderViewController") as! RegisterGenderViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func goLogin(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Login", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
