//
//  VersionViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/07.
//

import UIKit

class VersionViewController: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    
    var version: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    func configure() {
        guard let version = version else { return }
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
        versionLabel.text = "앱 버전: \(version)"
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
}
