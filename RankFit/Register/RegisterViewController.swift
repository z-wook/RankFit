//
//  RegisterViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/13.
//

import UIKit
import KakaoSDKUser
import KakaoSDKAuth
import Alamofire
import Combine

class RegisterViewController: UIViewController {

    var info: userInfo!
    var viewModel: AuthenticationModel!
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("------ > userInfo: \(info)")
        viewModel = AuthenticationModel()
        bind()
    }
    
    
    private func bind() {
        viewModel.userInfoData
            .receive(on: RunLoop.main)
            .sink { info in
                if let info = info {
                    let parameters: Parameters = [
                        "userID": info.userID ?? "정보없음", // 플랫폼 고유 아이디
                        "userEmail": info.email ?? "정보없음", // 이메일
                        "userNickname": info.nickName ?? "정보없음",
                        "userAge": "\(info.age ?? -1)",
                        "userSex": info.gender ?? "정보없음",
                        "userWeight": info.weight ?? -1
                    ]
                    
//                    AF.request("http://rankfit.site/RegisterTest.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseDecodable { response in
//                        print("///////// \(response)")
//                    }
                    
                    
                    AF.request("http://rankfit.site/RegisterTest.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString {
                        response in
                        print("////////////////// > response: \(response)") // success("true") / success("false")
                    }
                } else { return }
            }.store(in: &subscriptions)
        
    }

    @IBAction func kakao_Login(_ sender: UIButton) {
        // isKakaoTalkLoginAvailable() : 카톡 설치 되어있으면 true
        if (UserApi.isKakaoTalkLoginAvailable()) {
            
            //카톡 설치되어있으면 -> 카톡으로 로그인
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                } else {
                    print("카카오 톡으로 로그인 성공")
                    
                    _ = oauthToken
                    // 로그인 관련 메소드 추가
                    self.getUserInfo()
                    
                }
            }
        } else {
            // 카톡 없으면 -> 계정으로 로그인
            UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
                if let error = error {
                    print(error)
                } else {
                    print("카카오 계정으로 로그인 성공")
                    
                    _ = oauthToken
                    // 로그인 관련 메소드 추가
                    self.getUserInfo()
                    
                    
//                    let parameters: Parameters = [
//                        "userID": self.id ?? "정보없음",
//                        "userName": self.email ?? "정보없음", // 일단 이메일
//                        "userAge": "\(self.userInfomation.age ?? -1)" ,
//                        "userSex": "\(self.userInfomation.gender ?? "정보없음")",
//                        "userWeight": "\(self.userInfomation.weight ?? -1)"
//                    ]
//                    AF.request("http://rankfit.site/RegisterTest.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseJSON {
//                        response in
//                        print("////////////////// > response: \(response)")
//                    }
                    
                    
                    
                    
                    
                    
                    
//                    AF.request("http://rankfit.site/RegisterTest.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseDecodable { response in
//                        print("///////// \(response)")
//                    }

                    
                    
                    
                    
//                    // Onboarding후 화면 설정
//                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
//                    windowScene.windows.first?.rootViewController = MainTabBarController()
//                    windowScene.windows.first?.makeKeyAndVisible()
                }
            }
        }
    }
    
    func getUserInfo() {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                print("me() success.")
                //do something
                _ = user
                let userID = "\(user?.id ?? -1)" // 카카오 플랫폼 내에서 사용되는 사용자의 고유 아이디입니다.
                let email = user?.kakaoAccount?.email // 카카오계정에 등록된 이메일

                let infomation = userInfo(gender: self.info.gender, age: self.info.age, weight: self.info.weight, userID: "k" + userID, nickName: "일단아무거나", email: email)
                self.viewModel.userInfoData.send(infomation)
                
            }
        }
    }
}
