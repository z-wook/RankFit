//
//  VersionViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/07.
//

import UIKit

class VersionViewController: UIViewController {

    @IBOutlet weak var versionLabel: UILabel!
    
    var version: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    func configure() {
        guard let version = version else { return }
        versionLabel.text = "앱 버전: \(version)"
    }
}
