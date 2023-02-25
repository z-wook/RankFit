//
//  DiaryViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/11.
//

import UIKit
import FirebaseStorage
import AVFoundation
import Photos
import Combine

class DiaryViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    static var reloadDiary = PassthroughSubject<Bool, Never>()
    let subject = PassthroughSubject<[UIImage], Never>()
    let imgNameState = PassthroughSubject<[String], Never>()
    let downloadState = PassthroughSubject<String, Never>()
    let saveCoreState = PassthroughSubject<Bool, Never>()
    let deleteState = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
//    let db = Firestore.firestore()
    let storage = Storage.storage()
    let picker = UIImagePickerController()
    
    var photoList: [PhotoInfomation]! // CoreData에 저장된 사진 정보 리스트
    var sortedPhotoList: [PhotoInfomation]! // 프로필을 제외한 사진 정보 리스트
    var imageList: [UIImage]! // 최종 저장된 이미지 리스트
    var fireList: [String]! = [] // 파이어베이스에 저장된 사진 리스트
    var selectedIndexPath: [IndexPath: UIImage] = [:]
    
    typealias Item = UIImage
    enum Section {
        case main
    }
    
    enum Mode {
        case view
        case select
    }
    var mMode: Mode = .view {
        didSet {
            switch mMode {
            case .view:
                for (key, _) in selectedIndexPath {
                    collectionView.deselectItem(at: key, animated: true)
                }
                selectedIndexPath.removeAll()
                navigationItem.leftBarButtonItems = nil
                collectionView.allowsMultipleSelection = false
                return
                
            case .select:
                appearBarBtn()
                collectionView.allowsMultipleSelection = true
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        configureNavigationBar()
        configCollectionView()
        bind()
        getImageInfo()
    }
    
    private func bind() {
        DiaryViewController.reloadDiary.receive(on: RunLoop.main).sink { _ in
            print("Diary Reload")
            self.getImageInfo()
        }.store(in: &subscriptions)
        
        subject.receive(on: RunLoop.main).sink { imageInfoList in
            self.indicator.stopAnimating()
            self.imageList = imageInfoList
            self.applyItems(items: imageInfoList)
        }.store(in: &subscriptions)
        
        imgNameState.receive(on: RunLoop.main).sink { imgNameList in
            self.fireList = imgNameList
            // 서버에서 사진 다운 & 로컬에 사진 저장
            configFirebase.downloadImage(imgNameList: imgNameList, subject: self.downloadState)
        }.store(in: &subscriptions)
        
        downloadState.receive(on: RunLoop.main).sink { imgName in
            let timeStamp: Int64!
            // coreData에 파일 정보 저장
            if imgName != "false" {
                if imgName == "profileImage.jpeg" { // 프로필 사진이면 다르게 저장
                    timeStamp = Int64(TimeStamp.getCurrentTimestamp())
                } else {
                    // 여기서 saveTime을 파일 앞에 이름 따서 만들기
                    let startIndex = imgName.index(imgName.startIndex, offsetBy: 0) // 시작 인덱스
                    let endIndex = imgName.index(imgName.startIndex, offsetBy: 10) // 끝 인덱스
                    let sliced_str = imgName[startIndex ..< endIndex]
                    timeStamp = Int64(sliced_str) ?? Int64(TimeStamp.getCurrentTimestamp())
                }
                let photoinfo = PhotoInfomation(imageName: imgName, saveTime: timeStamp)
                let result = PhotoCoreData.saveCoreData(info: photoinfo)
                if result {
                    let data = PhotoCoreData.fetchCoreData()
                    if self.fireList.count == data.count {
                        // 모든 파일 다 내려오면 알려주기
                        self.saveCoreState.send(true)
                    }
                }
                else {
                    print("coreData에 저장 못함")
                    configFirebase.errorReport(type: "DiaryVC.bind/downloadState", descriptions: "CoerData에 저장 못함")
                    // doucument에서 file 삭제
                    configLocalStorage.deleteImageFromDocumentDirectory(imageName: imgName)
                }
            } else {
                print("로컬에 저장 못함")
                configFirebase.errorReport(type: "DiaryVC.bind/downloadState", descriptions: "Local에 저장 못함")
                self.indicator.stopAnimating()
            }
        }.store(in: &subscriptions)
        
        saveCoreState.receive(on: RunLoop.main).sink { result in
            if result {
                self.getImageInfo()
                SettingViewController.reloadProfile.send(true)
            }
        }.store(in: &subscriptions)
        
        deleteState.receive(on: RunLoop.main).sink { result in
            if result {
                print("reload Image")
                self.getImageInfo()
            }
        }.store(in: &subscriptions)
    }
    
    private func getImageInfo() {
        configLocalStorage.deleteImageFromDocumentDirectory(imageName: ".Trash")
        var ImageList: [[String: Any]] = []
        photoList = PhotoCoreData.fetchCoreData()
        
        // [파일이 저장되어 있는 경로 확인]
        let fileManager = FileManager.default // 파일 매니저 선언
        let fileSavePath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first! // 애플리케이션 저장 폴더

        // [애플리케이션 폴더에 저장되어 있는 파일 리스트 확인]
        var fileList : Array<Any>? = nil
        do {
            fileList = try FileManager.default.contentsOfDirectory(atPath: fileSavePath.path)
        }
        catch {
            print("Error: " + error.localizedDescription)
            configFirebase.errorReport(type: "DiaryVC.getImageInfo", descriptions: error.localizedDescription)
            indicator.stopAnimating()
            return
        }
        guard let fileList = fileList else {
            print("error: fileList 없음")
            configFirebase.errorReport(type: "DiaryVC.getImageInfo", descriptions: "fileList = nil")
            indicator.stopAnimating()
            return
        }
        print("fileList: \(fileList)")
        
        if photoList.count == fileList.count {
            for photoInfo in photoList {
                let time = photoInfo.saveTime
                let fileName = photoInfo.imageName
                if fileName == "profileImage.jpeg" { continue } // 프로필 사진은 눈바디에서 제외시키기
                let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: fileName)
                guard let image = image else {
                    print("error: 없는 이미지, 이미지 파일명 변경 오류")
                    configFirebase.errorReport(type: "DiaryVC.getImageInfo", descriptions: "image = nil, 이미지 파일명 변경 오류")
                    continue
                }
                let info: [String: Any] = ["saveTime": time, "image": image]
                ImageList.append(info)
            }
            // 사진 순서 정렬
            let sortedList = ImageList.sorted { prev, next in
                let prevTime = prev["saveTime"] as! Int64
                let nextTime = next["saveTime"] as! Int64
                return prevTime > nextTime
            }
            let sortedImage = sortedList.map { info in
                let image = info["image"] as! UIImage
                return image
            }
            subject.send(sortedImage)
        } else { // CoreData에 저장된 개수와 다른 상황 -> 파일 손상으로 간주
            let login = UserDefaults.standard.bool(forKey: "login")
            if login != true {
                return
            }
            // CoreData에 저장된 정보 모두 삭제
            for photo in photoList {
                let delete = PhotoCoreData.deleteCoreData(imageName: photo.imageName)
                if delete { print("사진 삭제 성공") }
                else {
                    print("사진 삭제 실패")
                    configFirebase.errorReport(type: "DiaryVC.getImageInfo", descriptions: "사진 삭제 실패")
                }
            }
            // 로컬에 저장된 사진 모두 삭제
            for file in fileList {
                let fileName = file as! String
                configLocalStorage.deleteImageFromDocumentDirectory(imageName: fileName)
            }
            // 서버에서 사진 이름 가져오기
            configFirebase.getImgNameFromFirebase(subject: imgNameState)
        }
    }
    
    private func appearBarBtn() {
        let saveConfig = CustomBarItemConfiguration(
            title: "저장",
            color: .white,
            handler: {
                if self.selectedIndexPath.isEmpty {
                    self.savePhoto(title: "선택한 사진 없음", description: "선택한 사진이 없습니다.")
                    return
                }
                for (_, value) in self.selectedIndexPath {
                    UIImageWriteToSavedPhotosAlbum(value, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
                self.mMode = self.mMode == .view ? .select : .view
                self.collectionView.allowsMultipleSelection = false
                self.savePhoto(title: "사진 저장 완료", description: "앨범에 사진을 저장했습니다.")
            }
        )
        let savetItem = UIBarButtonItem.generate(with: saveConfig, width: 50)
        savetItem.customView?.backgroundColor = .darkGray
        savetItem.customView?.layer.cornerRadius = 10
        
        let deleteConfig = CustomBarItemConfiguration(
            title: "취소",
            color: .white,
            handler: {
                self.mMode = self.mMode == .view ? .select : .view
                self.collectionView.allowsMultipleSelection = false
            }
        )
        let deleteItem = UIBarButtonItem.generate(with: deleteConfig, width: 50)
        deleteItem.customView?.backgroundColor = .darkGray
        deleteItem.customView?.layer.cornerRadius = 10
        navigationItem.leftBarButtonItems = [savetItem, deleteItem]
    }
}

extension DiaryViewController {
    private func configCollectionView() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyDiaryCell", for: indexPath) as? MyDiaryCell else { return nil }
            cell.config(Image: itemIdentifier)
            return cell
        })
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        dataSource.apply(snapshot)
        collectionView.delegate = self
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(1)
        
        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        section.interGroupSpacing = 1
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applyItems(items: [UIImage]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot)
    }
}

extension DiaryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if self.collectionView.allowsMultipleSelection == true {
            let cell = self.collectionView.cellForItem(at: indexPath)
            if cell?.isSelected == false {
                cell?.isSelected = true
                return true
            }
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if self.collectionView.allowsMultipleSelection == true {
            let cell = self.collectionView.cellForItem(at: indexPath)
            if cell?.isSelected == true {
                cell?.isSelected = false
                return true
            }
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "DetailPhotoViewController") as! DetailPhotoViewController
        guard let imageList = imageList else { return }
        guard let photoList = photoList else { return }
        let sortedList = photoList.filter { info in
            if info.imageName != "profileImage.jpeg" { return true }
            else { return false }
        }
        switch mMode {
        case .view:
            collectionView.deselectItem(at: indexPath, animated: true)
            let image = imageList[indexPath.item]
            let savetime = sortedList[indexPath.item].saveTime
            vc.reloadSubject = deleteState
            vc.info = sortedList[indexPath.item]
            vc.image = image
            vc.saveTime = Int(savetime)
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
            return
            
        case .select:
            selectedIndexPath[indexPath] = imageList[indexPath.item]
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if mMode == .select {
            selectedIndexPath.removeValue(forKey: indexPath)
        }
    }
}

extension DiaryViewController {
    private func configureNavigationBar() {
        let cameraConfig = CustomBarItemConfiguration(
            image: UIImage(systemName: "camera"),
            handler: {
                let alert = UIAlertController(title: "사진 가져오기", message: nil, preferredStyle: .actionSheet)
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
                if self.mMode == .select {
                    return
                }
                let alert = UIAlertController(title: "앨범에 저장", message: nil, preferredStyle: .actionSheet)
                let save = UIAlertAction(title: "사진 선택", style: .default) { (action) in
                    self.mMode = self.mMode == .view ? .select : .view
                }
                let saveAll = UIAlertAction(title: "모두 저장", style: .default) { (action) in
                    for image in self.imageList {
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                    self.savePhoto(title: "사진 저장 완료", description: "앨범에 사진을 저장했습니다.")
                }
//                let delete = UIAlertAction(title: "삭제", style: .destructive) { (action) in
//                    print("삭제")
//                }
                let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
                alert.addAction(save)
                alert.addAction(saveAll)
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
        )
        let moreItem = UIBarButtonItem.generate(with: moreConfig, width: 30)
        navigationItem.rightBarButtonItems = [moreItem, cameraItem]
        
        let backImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "눈바디"
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
    
    private func savePhoto(title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

extension DiaryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let sb = UIStoryboard(name: "Diary", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "PickImageViewController") as! PickImageViewController
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            vc.image = image
            vc.saveState = saveCoreState
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
        vc.modalTransitionStyle = .flipHorizontal
        present(vc, animated: true)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("error: \(error.localizedDescription)")
            configFirebase.errorReport(type: "DiaryVC.@image", descriptions: error.localizedDescription)
            return
        } else {
            print("앨범에 저장 성공")
        }
    }
}
