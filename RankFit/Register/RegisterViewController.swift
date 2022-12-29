//
//  RegisterViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/13.
//

import UIKit
import Alamofire
import Combine
import KakaoSDKUser
import KakaoSDKAuth
import NaverThirdPartyLogin

class RegisterViewController: UIViewController, NaverThirdPartyLoginConnectionDelegate {
    
    var info: userInfo!
    var viewModel: AuthenticationModel!
    var subscriptions = Set<AnyCancellable>()
    
    let loginInstance = NaverThirdPartyLoginConnection.getSharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = AuthenticationModel()
        bind()
        navigationItem.backButtonDisplayMode = .minimal
        
        // Naver
        loginInstance?.delegate = self
    }
    
    private func bind() {
        viewModel.userInfoData
            .receive(on: RunLoop.main)
            .sink { info in
                if (info?.userID != nil && info?.email != nil) {
                    let sb = UIStoryboard(name: "Register", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "RegisterNickNameViewController") as! RegisterNickNameViewController
                    vc.viewModel = self.viewModel
                    self.navigationController?.pushViewController(vc, animated: true)
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
                    self.getKakaoUserInfo()
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
                    self.getKakaoUserInfo()
                }
            }
        }
    }
    
    
    
    @IBAction func naver_Login(_ sender: UIButton) {
        loginInstance?.requestThirdPartyLogin()
    }
    
    
    @IBAction func naver_Logout(_ sender: UIButton) {
        loginInstance?.requestDeleteToken()
    }
    
    // 로그인에 성공한 경우 호출
    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        print("Success login")
        getNaverUserInfo()
    }
    // referesh token
    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        print("Naver Token = \(loginInstance?.accessToken ?? "nil")")
    }
    // 로그아웃
    func oauth20ConnectionDidFinishDeleteToken() {
        print("log out")
    }
    // 모든 error
    func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        print("error = \(error.localizedDescription)")
    }
    
    func getNaverUserInfo() {
        guard let isValidAccessToken = loginInstance?.isValidAccessTokenExpireTimeNow() else { return }
        
        if !isValidAccessToken {
            return
        }
        
        guard let tokenType = loginInstance?.tokenType else { return }
        guard let accessToken = loginInstance?.accessToken else { return }
        let requestUrl = "https://openapi.naver.com/v1/nid/me"
        let url = URL(string: requestUrl)!
        
        let authorization = "\(tokenType) \(accessToken)"
        
        let req = AF.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": authorization])
        
        req.responseJSON { response in
            guard let result = response.value as? [String: Any] else { return }
            guard let object = result["response"] as? [String: Any] else { return }
            
            guard let name = object["name"] as? String else { return }
            guard let email = object["email"] as? String else { return }
//            guard let nickname = object["nickname"] as? String else { return }
            
            print(response)
            print(result)
            print(object)
            print(name)
            print(email)
            
        }
    }
    
    func getKakaoUserInfo() {
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

                let infomation = userInfo(gender: self.info.gender, age: self.info.age, weight: self.info.weight, userID: "k" + userID, email: email)
                self.viewModel.userInfoData.send(infomation)
            }
        }
    }
}
