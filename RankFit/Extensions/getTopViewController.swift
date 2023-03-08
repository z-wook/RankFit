//
//  getTopViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation
import UIKit

extension UIWindow {
    public func visibleViewController() -> UIViewController? {
        var vc: UIViewController?
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            if let currentVC = window.rootViewController?.presentedViewController {
                vc = currentVC
            } else if let currentVC = window.rootViewController {
                vc = currentVC
            } else {
                print("현재 보이는 뷰가 없습니다.")
            }
            return vc
        } else {
            print("No Window Found")
            configFirebase.errorReport(type: "getTopViewController.visibleViewController", descriptions: "No Window Found")
            return nil
        }
    }
}
