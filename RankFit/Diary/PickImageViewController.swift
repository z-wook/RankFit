//
//  PickImageViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/18.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Combine

class PickImageViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let firebaseState = PassthroughSubject<String, Never>()
    let localState = PassthroughSubject<String, Never>()
    var saveState: PassthroughSubject<Bool, Never>! // 저장하고 뷰를 새로 그리기 위해 알려주는 subject
    var subscriptions = Set<AnyCancellable>()
    let byteSize: Int = 5242880 // 5MB
    var image: UIImage!
    var ImageData: Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }
    
    private func bind() {
        firebaseState.receive(on: RunLoop.main).sink { imgName in
            if imgName != "false" {
                configLocalStorage.saveImageToLocal(imageName: imgName, imgData: self.ImageData, subject: self.localState)
            } else {
                print("Firebase 사진 저장 실패")
                self.indicator.stopAnimating()
                self.showAlert(description: "잠시 후 다시 시도해 주세요.")
            }
        }.store(in: &subscriptions)
        
        localState.receive(on: RunLoop.main).sink { imgName in
            self.indicator.stopAnimating()
            if imgName != "false" {
                let startIndex = imgName.index(imgName.startIndex, offsetBy: 0) // 시작 인덱스
                let endIndex = imgName.index(imgName.startIndex, offsetBy: 10) // 끝 인덱스
                let sliced_str = imgName[startIndex ..< endIndex]
                let timeStamp = Int64(sliced_str) ?? Int64(TimeStamp.getCurrentTimestamp())
                let photoinfo = PhotoInformation(imageName: imgName, saveTime: timeStamp)
                let result = PhotoCoreData.saveCoreData(info: photoinfo)
                if result {
                    self.saveState.send(true)
                    self.isModalInPresentation = false
                    self.dismiss(animated: true)
                } else {
                    print("CoreData에 저장 못함")
                    configFirebase.errorReport(type: "PickImageVC.bind/LocalState", descriptions: "CoreData에 저장 못함")
                    self.showAlert(description: "잠시 후 다시 시도해 주세요.")
                }
            } else {
                print("로컬에 저장 못함")
                self.showAlert(description: "잠시 후 다시 시도해 주세요.")
            }
        }.store(in: &subscriptions)
    }
    
    @IBAction func close(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func UploadBtn(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        guard user != nil else {
            loginAlert()
            return
        }
        saveBtn.isEnabled = false
        self.isModalInPresentation = true
        backgroundView.isHidden = false
        indicator.startAnimating()
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            print("이미지 압축에 실패했습니다.")
            configFirebase.errorReport(type: "PickIamgeVC.UploadBtn", descriptions: "이미지 압축 실패")
            saveBtn.isEnabled = true
            self.isModalInPresentation = false
            backgroundView.isHidden = true
            indicator.stopAnimating()
            return
        }
        if data.count > byteSize {
            showAlert(description: "선택한 사진의 용량이 너무 커서 사진을 저장할 수 없습니다.")
            return
        }
        ImageData = data
        configFirebase.savePhoto(imgData: data, subject: firebaseState)
    }
}

extension PickImageViewController {
    private func configure() {
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        scrollView.delegate = self
        imgView.image = image
        saveBtn.layer.cornerRadius = 20
    }
    
    private func showAlert(description: String) {
        let alert = UIAlertController(title: "사진 저장 실패", message: description, preferredStyle: UIAlertController.Style.alert)
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
}

extension PickImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
}
