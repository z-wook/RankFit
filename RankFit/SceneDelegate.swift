//
//  SceneDelegate.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import CoreLocation
import FirebaseAuth
import Combine
//import NotificationCenter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // FirebaseAuth
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let webpageURL = userActivity.webpageURL else { return }
        let link = webpageURL.absoluteString
        
        if Auth.auth().isSignIn(withEmailLink: link) {
            if checkRegister.shared.isNewUser() {
                if UserDefaults.standard.bool(forKey: "login") {
                    print("로그인")
                    let notiName = NSNotification.Name("login")
                    NotificationCenter.default.post(name: notiName, object: nil, userInfo: ["link": link])
                    return
                } else {
                    print("회원가입")
                    let notiName = NSNotification.Name("register")
                    NotificationCenter.default.post(name: notiName, object: nil, userInfo: ["link": link])
                    return
                }
            } else {
                if UserDefaults.standard.bool(forKey: "revoke") {
                    print("탈퇴")
                    let notiName = NSNotification.Name("revoke")
                    NotificationCenter.default.post(name: notiName, object: nil, userInfo: ["link": link])
                    return
                } else {
                    print("로그인")
                    let notiName = NSNotification.Name("login")
                    NotificationCenter.default.post(name: notiName, object: nil, userInfo: ["link": link])
                    return
                }
            }
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        let rawValue = UserDefaults.standard.integer(forKey: "Appearance")
        window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: rawValue) ?? .unspecified
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
//        UIApplication.shared.applicationIconBadgeNumber = 0 // 알림 배지를 초기화

        let notiName = NSNotification.Name("WillEnterForeground")
        NotificationCenter.default.post(name: notiName, object: nil)
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        
        let notiName = NSNotification.Name("DidEnterBackground")
        NotificationCenter.default.post(name: notiName, object: nil)
    }
}
