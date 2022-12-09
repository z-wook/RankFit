//
//  MainTabBarController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    

}
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let aaa = viewController.restorationIdentifier
        //        print("---> tapped: \(aaa)")

    }
}
