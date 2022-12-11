//
//  HomeViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import UIKit
import KakaoSDKUser
import KakaoSDKAuth

class HomeViewController: UIViewController {

    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    
    var nickname: String? // 이름
    var email: String?
    var Gender: Gender?
    var AgeRange: AgeRange?
    var profileImageUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func tapped_login(_ sender: UIButton) {
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
                    let accessToken = oauthToken?.accessToken
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
                    let accessToken = oauthToken?.accessToken
                    print("=====> accessToken: \(accessToken)")
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
                
                let nickname = user?.kakaoAccount?.profile?.nickname
                let email = user?.kakaoAccount?.email
                let gender = user?.kakaoAccount?.gender
                let ageRange = user?.kakaoAccount?.ageRange
//                let profileImageUrl = user?.kakaoAccount?.profile?.profileImageUrl
                
                self.nickname = nickname
                self.email = email
                self.Gender = gender
                self.AgeRange = ageRange
                
                self.nickNameLabel.text = self.nickname
                self.emailLabel.text = self.email
                self.genderLabel.text = self.Gender?.rawValue
                self.ageLabel.text = self.AgeRange?.rawValue
                
            }
        }
    }
}
