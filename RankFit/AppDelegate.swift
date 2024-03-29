//
//  AppDelegate.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import FirebaseRemoteConfig
import UserNotifications
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var remoteConfig: RemoteConfig?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.applicationIconBadgeNumber = 0 // 알림 배지를 초기화
        
        // Firebase 초기화 세팅
        FirebaseApp.configure()
        configureFirebaseRemoteConfig()
        getNotice()
        
        if Core.shared.isNewUser() == false {
            // 앱이 시작될 때 푸시 알림 등록을 시도
            registerRemoteNotification()
            // auth reload
            Auth.auth().currentUser?.reload(completion: { error in
                if let error = error {
                    let error = error.localizedDescription
                    if error == "The user account has been disabled by an administrator." {
                        DispatchQueue.main.async {
                            self.suspendtAlert()
                        }
                    }
                }
            })
        }
        // 메시지 delegate 설정
        Messaging.messaging().delegate = self
        
        sleep(1) // for Launch Screen
        return true
    }
    
    func registerRemoteNotification() {
        // 푸시 알림 권한 설정 및 푸시 알림에 앱 등록(foreground)
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        center.requestAuthorization(options: options) { granted, _ in
            print("Permission granted: \(granted)")
            guard granted else {
                print("----> 알림 수신 거부")
                return
            }
            self.getNotificationSettings()
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            // APNs에 device token 등록 요청
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // APNs 토큰과 등록 토큰 매핑
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error.localizedDescription)")
    }
    
    // 백그라운드에서 자동 푸시 알림 처리
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        let user = Auth.auth().currentUser
        
        let suspension = userInfo["Suspension"] as? String
        let userID = userInfo["userID"] as? String
        
        // 계정 정치 처리
        if let suspension = suspension, let userID = userID {
            let uid = saveUserData.getKeychainStringValue(forKey: .UID)
            if suspension == "true" && userID == uid { // 본인 확인 통과
                if user == nil { // 로그아웃 상태면 알람만
                    suspendtAlert()
                } else {
                    suspendUser()
                }
            }
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // auth reload
        Auth.auth().currentUser?.reload(completion: { error in
            if let error = error {
                let error = error.localizedDescription
                if error == "The user account has been disabled by an administrator." {
                    DispatchQueue.main.async {
                        self.suspendtAlert()
                    }
                }
            }
        })
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "RankFit")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // 화면 세로방향 고정
        return UIInterfaceOrientationMask.portrait
    }
}

extension AppDelegate: MessagingDelegate {
    // 현재 등록 토큰 가져오기 / fcm 등록 토큰을 받았을 때
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let user = Auth.auth().currentUser
        guard let fcmToken = fcmToken else {
            print("fcmToken == nil")
            configFirebase.errorReport(type: "AppDelegate.messaging", descriptions: "fcmToken == nil")
            return
        }
        print("FCMToken 토큰: \(fcmToken)")
        let token = saveUserData.getKeychainStringValue(forKey: .Token)
        guard let token = token else { // token == nil
            // 키체인에 저장
            saveUserData.setKeychain(fcmToken, forKey: .Token)
            return
        }
        if token != fcmToken { // 키체인 확인 후 다르면 저장
            saveUserData.removeKeychain(forKey: .Token) // 기존 토큰값 삭제
            saveUserData.setKeychain(fcmToken, forKey: .Token)
        }
        if user != nil { // 로그인 되어있다면 토큰 값 갱신
            configFirebase.updateToken(Token: fcmToken)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {    
    // 푸시 메시지를 받았을 때(foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        let user = Auth.auth().currentUser
        
        let suspension = userInfo["Suspension"] as? String
        let userID = userInfo["userID"] as? String
        
        // 계정 정지 처리
        if let suspension = suspension, let userID = userID {
            let uid = saveUserData.getKeychainStringValue(forKey: .UID)
            if suspension == "true" && userID == uid { // 본인 확인 통과
                if user == nil { // 로그아웃 상태면 알람만
                    suspendtAlert()
                } else {
                    suspendUser()
                }
            }
        }
        completionHandler([.badge, .banner, .sound])
    }
    
    // 푸시 메시지를 받았을 때(background)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let user = Auth.auth().currentUser
        
        let suspension = userInfo["Suspension"] as? String
        let userID = userInfo["userID"] as? String
        
        // 계정 정지 처리
        if let suspension = suspension, let userID = userID {
            let uid = saveUserData.getKeychainStringValue(forKey: .UID)
            if suspension == "true" && userID == uid { // 본인 확인 통과
                if user == nil { // 로그아웃 상태면 알람만
                    suspendtAlert()
                } else {
                    suspendUser()
                }
            }
        }
        completionHandler()
    }
    
    // 사용자 계정 reload
    private func suspendUser() {
        Auth.auth().currentUser?.reload(completion: { error in
            if let error = error {
                let error = error.localizedDescription
                if error == "The user account has been disabled by an administrator." {
                    DispatchQueue.main.async {
                        self.suspendtAlert()
                        return
                    }
                } else {
                    let uid = saveUserData.getKeychainStringValue(forKey: .UID) ?? ""
                    configFirebase.errorReport(type: "AppDelegate.suspendUser", descriptions: "사용자 계정 정지 실패_ \(uid)")
                }
            }
        })
    }
    
    // 계정 정지 알람
    private func suspendtAlert() {
        let vc = getCurrentViewController()
        guard let vc = vc else { return }
        let alertController = UIAlertController(title: "계정 사용 중지됨", message: "귀하의 계정이 사용 중지되었습니다. 문의사항은 관리자에게 해주세요.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .destructive) { _ in
            UIApplication.shared.applicationIconBadgeNumber = 0 // 알림 배지를 초기화
        }
        alertController.addAction(okAction)
        vc.present(alertController, animated: true)
    }
}

extension AppDelegate {
    private func configureFirebaseRemoteConfig() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 900     // 15분
        remoteConfig?.configSettings = settings
        remoteConfig?.setDefaults(fromPlist: "RemoteConfigDefaults")
    }
    
    private func getNotice() {
        guard let remoteConfig = remoteConfig else { return }
        remoteConfig.fetch { status, error in
            if status == .success {
                print("Config fetched!")
                remoteConfig.activate { changed, error in
                    guard error == nil else {
                        print("Error: \(String(describing: error?.localizedDescription))")
                        configFirebase.errorReport(type: "HomeVC.getNotice", descriptions: error?.localizedDescription ?? "nil")
                        return
                    }
                    if self.isNoticeHidden(remoteConfig) == false {
                        DispatchQueue.main.async {
                            let currentVC = self.getCurrentViewController()
                            guard let currentVC = currentVC else { return }
                            let noticeVC = NoticeVC(nibName: "NoticeVC", bundle: nil)
                            noticeVC.modalPresentationStyle = .custom
                            noticeVC.modalTransitionStyle = .crossDissolve
                            
                            let title = (remoteConfig["title"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                            let detail = (remoteConfig["detail"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                            let date = (remoteConfig["date"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                            noticeVC.noticeContents = (title: title, detail: detail, date: date)
                            
                            currentVC.present(noticeVC, animated: true)
                        }
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
                configFirebase.errorReport(type: "HomeVC.getNotice", descriptions: error?.localizedDescription ?? "Config not fetched")
            }
        }
    }
    
    private func isNoticeHidden(_ remoteConfig: RemoteConfig) -> Bool {
        return remoteConfig["isHidden"].boolValue
    }
}
