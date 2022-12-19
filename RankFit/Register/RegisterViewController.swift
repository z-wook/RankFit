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
        viewModel = AuthenticationModel()
        bind()
        navigationItem.backButtonDisplayMode = .minimal
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

                let infomation = userInfo(gender: self.info.gender, age: self.info.age, weight: self.info.weight, userID: "k" + userID, email: email)
                self.viewModel.userInfoData.send(infomation)
            }
        }
    }
}
