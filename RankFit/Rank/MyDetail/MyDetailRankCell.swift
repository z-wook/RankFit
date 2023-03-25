//
//  MyDetailRankCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/02.
//

import UIKit
import Alamofire

class MyDetailRankCell: UICollectionViewCell {
    
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var reportBtn: UIButton!
    
    var img: UIImage!
    var request: DataRequest!
    
    // Cache할 객체의 key값을 String으로 생성
    private var imageCache = NSCache<NSString, UIImage>()
    
    override func awakeFromNib() {
        profile.layer.cornerRadius = 20
        self.layer.borderColor = CGColor(red: 0.7, green: 0.5, blue: 1, alpha: 1)
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 20
        self.profile.isUserInteractionEnabled = true
        self.profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.zoomProfile(_:))))
    }
    
    @objc func zoomProfile(_ sender: UITapGestureRecognizer) {
        var image: UIImage!
        if nickName.text == "나의 랭킹" {
            guard let img = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg") else {
                MyRankViewController.profileSubject.send(UIImage(named: "blank_profile")!)
                return
            }
            image = img
        } else {
            let profileImage = imageCache.object(forKey: nickName.text! as NSString)
            guard let profileImage = profileImage else {
                MyRankViewController.profileSubject.send(UIImage(named: "blank_profile")!)
                return
            }
            image = profileImage
        }
        MyRankViewController.profileSubject.send(image)
    }
    
    func config(rank: String, nickname: String, score: String) {
        if nickname == "나의 랭킹" { // 맨 처음 나의 랭킹만 예외로 적용
            contentView.backgroundColor = UIColor(cgColor: CGColor(red: 0.5, green: 0, blue: 0.5, alpha: 0.6))
            reportBtn.layer.isHidden = true
            rankLabel.text = nickname
            nickName.text = rank + "위"
            scoreLabel.text = score + "점"
            let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg")
            guard let image = image else {
                profile.image = UIImage(named: "blank_profile")
                return
            }
            profile.image = image
        } else {
            loadImage(nickName: nickname)
            contentView.backgroundColor = .secondarySystemBackground
            reportBtn.layer.isHidden = false
            rankLabel.text = rank + "위"
            nickName.text = nickname
            scoreLabel.text = score + "점"
            profile.image = img
        }
    }
}

extension MyDetailRankCell {
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
                print("error: " + error.localizedDescription)
                configFirebase.errorReport(type: "OptionCell.loadImage", descriptions: error.localizedDescription, server: response.debugDescription)
                DispatchQueue.main.async {
                    self.indicator.stopAnimating()
                    self.profile.image = UIImage(named: "blank_profile")
                }
                return
            }
        }
    }
}
