//
//  OptionCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/03.
//

import UIKit
import Alamofire

class OptionCell: UICollectionViewCell {
    
    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var reportBtn: UIButton!
    
    var userInfo: OptionRankInfo!
    var img: UIImage!
    var request: DataRequest!
    enum Error: String {
        case cancelled = "Request explicitly cancelled."
        case failed = "URLSessionTask failed with error: 네트워크 연결이 유실되었습니다."
    }
    
    // Cache할 객체의 key값을 String으로 생성
    private var imageCache = NSCache<NSString, UIImage>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = CGColor(red: 0.7, green: 0.5, blue: 1, alpha: 1)
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 20
        profile.layer.cornerRadius = 20
        self.profile.isUserInteractionEnabled = true
        self.profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.zoomProfile(_:))))
    }
    
    @objc func zoomProfile(_ sender: UITapGestureRecognizer) {
        var image: UIImage!
        if userInfo.Nickname == "나의 랭킹" {
            guard let img = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg") else {
                MyRankViewController.profileSubject.send(UIImage(named: "blank_profile")!)
                return
            }
            image = img
        } else {
            let profileImage = imageCache.object(forKey: userInfo.Nickname as NSString)
            guard let profileImage = profileImage else {
                MyRankViewController.profileSubject.send(UIImage(named: "blank_profile")!)
                return
            }
            image = profileImage
        }
        MyRankViewController.profileSubject.send(image)
    }
    
    func configure(info: OptionRankInfo) {
        self.userInfo = info
        if info.Nickname == "나의 랭킹" { // 맨 처음 나의 랭킹만 예외로 적용
            contentView.backgroundColor = UIColor(cgColor: CGColor(red: 0.5, green: 0, blue: 0.5, alpha: 0.6))
            reportBtn.layer.isHidden = true
            nickName.text = info.Ranking + "위"
            rank.text = info.Nickname
            score.text = info.Score + "점"
            let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg")
            guard let image = image else {
                profile.image = UIImage(named: "blank_profile")
                return
            }
            profile.image = image
        } else {
            loadImage(nickName: info.Nickname)
            contentView.backgroundColor = .secondarySystemBackground
            reportBtn.layer.isHidden = false
            rank.text = info.Ranking + "위"
            nickName.text = info.Nickname
            score.text = info.Score + "점"
            profile.image = img
        }
    }
}

extension OptionCell {
    private func loadImage(nickName: String) {
        img = nil
        
        if let request = request {
            request.cancel()
        }
        
        // Cache된 이미지가 존재하면 해당 이미지를 사용 (API 호출 안하는 형태)
        if let imageFromCache = imageCache.object(forKey: nickName as NSString) {
            self.img = imageFromCache
            return
        }
        indicator.startAnimating()
        let parameters: Parameters = [
            "nickname": nickName
        ]
        request = AF.request("http://rankfit.site/imageDown.php", method: .post, parameters: parameters).responseData { response in
            switch response.result {
            case .success(let data):
                let image = UIImage(data: data)
                guard let image = image else {
                    DispatchQueue.main.async {
                        self.indicator.stopAnimating()
                        self.profile.image = UIImage(named: "blank_profile")
                    }
                    return
                }
                // 캐싱(캐시에 저장)
                self.imageCache.setObject(image, forKey: nickName as NSString)
                DispatchQueue.main.async {
                    self.indicator.stopAnimating()
                    self.profile.image = image
                }
                return
                
            case .failure(let error):
                let error = error.localizedDescription
                print("error: \(error)")
                if error == Error.cancelled.rawValue { return } // 랭킹을 로딩 중 취소하는 경우
                else if error == Error.failed.rawValue { return } // 네트워크 연결 유실
                else {
                    configFirebase.errorReport(type: "OptionCell.loadImage", descriptions: error, server: response.debugDescription)
                    DispatchQueue.main.async {
                        self.indicator.stopAnimating()
                        self.profile.image = UIImage(named: "blank_profile")
                    }
                }
            }
        }
    }
}
