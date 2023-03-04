//
//  DetailPhotoViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/21.
//

import UIKit
import FirebaseAuth
import Combine

class DetailPhotoViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let firebaseState = PassthroughSubject<Bool, Never>()
    let localState = PassthroughSubject<Bool, Never>()
    var reloadSubject: PassthroughSubject<Bool, Never>!
    var subscriptions = Set<AnyCancellable>()
    
    var info: PhotoInfomation!
//    var image: UIImage!
//    var saveTime: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    @IBAction func closeBtn(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func deletePhoto(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert()
            return
        }
        showMessage()
    }
    
    private func bind() {
        firebaseState.receive(on: RunLoop.main).sink { result in
            self.indicator.stopAnimating()
            if result {
                // 로컬에서 삭제
                configLocalStorage.deleteImageFromDocumentDirectory(imageName: self.info.imageName)
                // CoreData에서 삭제
                let result = PhotoCoreData.deleteCoreData(imageName: self.info.imageName)
                if result {
                    self.reloadSubject.send(true)
                    self.isModalInPresentation = false
                    self.dismiss(animated: true)
                } else {
                    configFirebase.errorReport(type: "DetailPhotoVC.bind", descriptions: "CoreData에서 이미지 정보 삭제 실패")
                    self.showAlert()
                }
            } else {
                print("다시 시도해 주세요.")
                self.showAlert()
            }
        }.store(in: &subscriptions)
    }
    
    private func showMessage() {
        let alert = UIAlertController(title: "사진을 삭제하시겠습니까?", message: nil, preferredStyle: .actionSheet)
        let ok = UIAlertAction(title: "삭제", style: .destructive) { action in
            self.isModalInPresentation = true
            self.backgroundView.isHidden = false
            self.indicator.startAnimating()
            // firebase에서 이미지 삭제
            configFirebase.deleteImageFromFirebase(imageName: self.info.imageName, subject: self.firebaseState)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "사진 저장 실패", message: "잠시 후 다시 시도해 주세요.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.isModalInPresentation = false
            self.dismiss(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func loginAlert() {
        let alert = UIAlertController(title: "로그아웃 상태", message: "현재 로그아웃 되어있어 사진을 저장할 수 없습니다.\n로그인을 먼저 해주세요.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func configure() {
        loadImage(info: info)
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        scrollView.delegate = self
        let str = TimeStamp.convertTimeStampToDate(timestamp: Int(info.saveTime))
        let startIndex = str.index(str.startIndex, offsetBy: 0) // 시작 인덱스
        let middleIndex = str.index(str.startIndex, offsetBy: 10) // 중간 인덱스
        let endIndex = str.index(str.startIndex, offsetBy: 15) // 끝 인덱스
        let sliced_date = str[startIndex ..< middleIndex]
        let sliced_time = str[middleIndex ..< endIndex]
        
        let dateStr = String(sliced_date)
        let timeStr = String(sliced_time)
        dateLabel.text = dateStr
        timeLabel.text = timeStr
    }
    
    private func loadImage(info: PhotoInfomation) {
        let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: info.imageName)
        guard let image = image else { return }
        DispatchQueue.main.async {
            self.imgView.image = image
        }
    }
}

extension DetailPhotoViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
}
