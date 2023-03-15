//
//  ChoiceWayViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/29.
//

import UIKit

class ChoiceWayViewController: UIViewController {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var buttonView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    private func configure() {
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .never
        buttonView.layer.cornerRadius = 10
        
        if self.traitCollection.userInterfaceStyle == .light {
            // 라이트모드
            imgView.image = UIImage(named: "logo1.png")
        } else if self.traitCollection.userInterfaceStyle == .dark {
            // 다크모드
            imgView.image = UIImage(named: "logo2.png")
        } else { // unspecified
            // 라이트모드로 기본 설정
            imgView.image = UIImage(named: "logo1.png")
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.userInterfaceStyle == .light {
            // 라이트모드
            DispatchQueue.main.async {
                self.imgView.image = UIImage(named: "logo1.png")
            }
        } else if self.traitCollection.userInterfaceStyle == .dark {
            // 다크모드
            DispatchQueue.main.async {
                self.imgView.image = UIImage(named: "logo2.png")
            }
        } else {
            DispatchQueue.main.async {
                self.imgView.image = UIImage(named: "logo1.png")
            }
        }
    }
    
    @IBAction func goRegister(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegisterGenderViewController") as! RegisterGenderViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func goLogin(_ sender: UIButton) {
        showLoginType()
    }
    
    private func showLoginType() {
        let sb = UIStoryboard(name: "Login", bundle: nil)
        let alert = UIAlertController(title: "로그인 인증 선택", message: nil, preferredStyle: .alert)
        let email = UIAlertAction(title: "이메일 인증 로그인", style: .default) { _ in
            let vc = sb.instantiateViewController(withIdentifier: "EmailLoginViewController") as! EmailLoginViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let password = UIAlertAction(title: "비밀번호 인증 로그인", style: .default) { _ in
            let vc = sb.instantiateViewController(withIdentifier: "PasswordLoginViewController") as! PasswordLoginViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let cancel = UIAlertAction(title: "취소", style: .destructive)
        alert.addAction(email)
        alert.addAction(password)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
}
