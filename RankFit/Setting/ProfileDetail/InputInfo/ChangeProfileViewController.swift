//
//  ChangeProfileViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/13.
//

import UIKit
import AVFoundation
import Photos
import Alamofire
import Combine

class ChangeProfileViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let viewModel = InputInfoViewModel()
    let picker = UIImagePickerController()
    let fireState = PassthroughSubject<String, Never>()
    let serverState = PassthroughSubject<Bool, Never>()
    let localState = PassthroughSubject<String, Never>()
    let deleteFireState = PassthroughSubject<Bool, Never>()
    let deleteServerState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    let byteSize: Int = 5242880 // 5MB
    var image: UIImage!
    var ImageData: Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configure()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isUserInteractionEnabled = true
    }
    
    private func configure() {
        picker.delegate = self
        scrollView.delegate = self
        imgView.image = image
        saveBtn.layer.cornerRadius = 10
        saveBtn.layer.isHidden = true
        backgroundView.backgroundColor = .black.withAlphaComponent(0.6)
        backgroundView.isHidden = true
        
        let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg")
        guard let image = image else {
            imgView.image = UIImage(named: "blank_profile")
            return
        }
        imgView.image = image
    }
    
    private func bind() {
        fireState.receive(on: RunLoop.main).sink { imgName in
            if imgName != "false" {
                self.viewModel.uploadToServer(ImageData: self.ImageData, subject: self.serverState)
            } else {
                print("프로필 사진 업데이트 실패")
                self.indicator.stopAnimating()
                self.showAlert(title: "프로필 사진 변경 실패")
            }
        }.store(in: &subscriptions)
        
        serverState.receive(on: RunLoop.main).sink { result in
            if result {
                configLocalStorage.saveImageToLocal(imageName: "profileImage", imgData: self.ImageData, subject: self.localState)
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "프로필 사진 변경 실패")
            }
        }.store(in: &subscriptions)
        
        localState.receive(on: RunLoop.main).sink { imgName in
            if imgName != "false" {
                let check = PhotoCoreData.profileInfo_exist_inCoreData()
                if check { // CoreData에 저장된 프로필 정보 있으므로 삭제 후 저장
                    let deleteResult = PhotoCoreData.deleteCoreData(imageName: "profileImage.jpeg")
                    if deleteResult == true {
                        print("CoreData에 저장되있던 프로필 사진 정보 삭제 성공")
                    } else { // 에러처리 해야하지만 viewDidLoad에 복구코드가 있으므로 에러 report만 함
                        configFirebase.errorReport(type: "ChangeProfileVC.bind/localState", descriptions: "CoreData에 저장되있던 프로필 사진 정보 삭제 실패")
                    }
                }
                let timeStamp = Int64(TimeStamp.getCurrentTimestamp())
                let photoinfo = PhotoInfomation(imageName: imgName, saveTime: timeStamp)
                let result = PhotoCoreData.saveCoreData(info: photoinfo)
                if result {
                    print("Complete")
                    SettingViewController.reloadProfile.send(true)
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    print("CoreData에 저장 못함")
                    configLocalStorage.deleteImageFromDocumentDirectory(imageName: "profileImage.jpeg")
                    configFirebase.errorReport(type: "ChangeProfileVC.bind/LocalState", descriptions: "CoreData에 저장 못함")
                    self.indicator.stopAnimating()
                    self.showAlert(title: "프로필 사진 변경 실패")
                }
            } else { // 에러처리 해야하지만 viewDidLoad에 복구코드가 있으므로 에러 report만 함
                print("로컬에 저장 못함")
                self.indicator.stopAnimating()
                self.showAlert(title: "프로필 사진 변경 실패")
            }
        }.store(in: &subscriptions)
        
        deleteFireState.receive(on: RunLoop.main).sink { result in
            if result {
                // 서버에서 사진 삭제
                self.viewModel.deleteFromServer(subject: self.deleteServerState)
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "프로필 사진 삭제 실패")
            }
        }.store(in: &subscriptions)
        
        deleteServerState.receive(on: RunLoop.main).sink { result in
            if result {
                let deleteResult = PhotoCoreData.deleteCoreData(imageName: "profileImage.jpeg")
                if deleteResult {
                    configLocalStorage.deleteImageFromDocumentDirectory(imageName: "profileImage.jpeg")
                    SettingViewController.reloadProfile.send(true)
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    configFirebase.errorReport(type: "ChangeProfileVC.bind/deleteState", descriptions: "CoreData에서 사진 삭제 실패")
                    self.indicator.stopAnimating()
                    self.showAlert(title: "프로필 사진 삭제 실패")
                }
            } else {
                self.indicator.stopAnimating()
                self.showAlert(title: "프로필 사진 삭제 실패")
            }
        }.store(in: &subscriptions)
    }
    
    @IBAction func UploadBtn(_ sender: UIButton) {
        guard let image = image else { return }
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            print("압축이 실패했습니다.")
            configFirebase.errorReport(type: "ChangeProfileVC.UploadBtn", descriptions: "이미지 압축 실패")
            showAlert(title: "프로필 사진 변경 실패")
            return
        }
        if data.count > byteSize {
            sizeAlert()
            return
        }
        saveBtn.isEnabled = false
        backgroundView.isHidden = false
        indicator.startAnimating()
        self.tabBarController?.tabBar.isUserInteractionEnabled = false
        ImageData = data
        configFirebase.savePhoto(type: "profile", imgData: data, subject: fireState)
    }
    
    private func showAlert(title: String) {
        let alert = UIAlertController(title: title, message: "잠시 후 다시 시도해 주세요.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension ChangeProfileViewController {
    private func configureNavigationBar() {
        let cameraConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "camera"),
            handler: {
                let alert = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)
                let library = UIAlertAction(title: "사진앨범", style: .default) { (action) in self.openLibrary()
                }
                let camera = UIAlertAction(title: "카메라", style: .default) { (action) in
                    self.openCamera()
                }
                let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
                alert.addAction(library)
                alert.addAction(camera)
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
        )
        let cameraItem = UIBarButtonItem.generate(with: cameraConfig, width: 30)
        let moreConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "ellipsis"),
            handler: {
                let alert = UIAlertController(title: "프로필 삭제", message: "프로필 사진을 삭제하시겠습니까?", preferredStyle: .alert)
                let ok = UIAlertAction(title: "프로필 유지", style: .default)
                let cancel = UIAlertAction(title: "프로필 삭제", style: .destructive) { _ in
                    let img = configLocalStorage.loadImageFromDocumentDirectory(imageName: "profileImage.jpeg")
                    if img == nil { return }
                    else {
                        self.backgroundView.layer.isHidden = false
                        self.indicator.startAnimating()
                        configFirebase.deleteImageFromFirebase(type: "profile", imageName: "profileImage", subject: self.deleteFireState)
                    }
                }
                alert.addAction(cancel)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        )
        let moreItem = UIBarButtonItem.generate(with: moreConfig, width: 30)
        navigationItem.rightBarButtonItems = [moreItem, cameraItem]
        navigationItem.title = "프로필 사진 변경"
    }
    
    private func openLibrary() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    print("Album: 권한 허용")
                    self.picker.sourceType = .photoLibrary
                    self.present(self.picker, animated: true)
                }
                
            default:
                DispatchQueue.main.async {
                    self.showAlert(reason: "사진 접근 요청 거부됨", discription: "설정 > 사진 접근 권한을 허용해 주세요.")
                }
            }
        }
    }
    
    private func openCamera() {
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                print("Camera: 권한 허용")
                DispatchQueue.main.async {
                    self.picker.sourceType = .camera
                    self.picker.cameraFlashMode = .off
                    self.present(self.picker, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    print("Camera: 권한 거부")
                    self.showAlert(reason: "카메라 접근 요청 거부됨", discription: "설정 > 카메라 접근 권한을 허용해 주세요.")
                }
            }
        }
    }
    
    private func showAlert(reason: String, discription: String) {
        let alert = UIAlertController(title: reason, message: discription, preferredStyle: .alert)
        let ok = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            // 설정으로 이동
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        let cancle = UIAlertAction(title: "취소", style: .default, handler: nil)
        // 색상 적용.
        cancle.setValue(UIColor.darkGray, forKey: "titleTextColor")
        alert.addAction(cancle)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func sizeAlert() {
        let alert = UIAlertController(title: "프로필 변경 실패", message: "선택한 사진의 용량이 너무 커서 프로필을 변경할 수 없습니다.", preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.isModalInPresentation = false
            self.dismiss(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension ChangeProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imgView.image = image
            self.image = image
            self.saveBtn.layer.isHidden = false
        }
        if let imageURL = info[UIImagePickerController.InfoKey.imageURL] as? URL {
            print("Image URL: \(imageURL)")
        }
        
        dismiss(animated: true)
        
        if picker.sourceType == .camera {
            if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("error: \(error.localizedDescription)")
            configFirebase.errorReport(type: "ChangeProfileVC.@image", descriptions: error.localizedDescription)
            return
        } else {
            print("앨범에 저장 성공")
        }
    }
}

extension ChangeProfileViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
}
