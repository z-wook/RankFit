//
//  getTopViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation
import UIKit

extension UIWindow {
    public var visibleViewController: UIViewController? {
        return self.visibleViewControllerFrom(vc: self.rootViewController)
    }
    
    public func visibleViewControllerFrom(vc: UIViewController? = UIApplication.shared.windows.first?.rootViewController) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return self.visibleViewControllerFrom(vc: nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return self.visibleViewControllerFrom(vc: tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return self.visibleViewControllerFrom(vc: pvc)
            } else {
                return vc
            }
        }
    }
}
