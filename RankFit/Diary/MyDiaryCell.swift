//
//  MyDiaryCell.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/20.
//

import UIKit

class MyDiaryCell: UICollectionViewCell {
    
    @IBOutlet weak var ImageView: UIImageView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var img: UIImage!
    var select: Bool = false
    
    // Cache할 객체의 key값을 String으로 생성
    private var imageCache = NSCache<NSString, UIImage>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        frontView.backgroundColor = .white.withAlphaComponent(0.6)
    }
    
    func configure(info: PhotoInformation) {
        loadImage(info: info)
        if select {
            frontView.isHidden = false
        } else {
            frontView.isHidden = true
        }
        ImageView.image = img
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                frontView.isHidden = false
                select = true
            } else {
                frontView.isHidden = true
                select = false
            }
        }
    }
}

extension MyDiaryCell {
    private func loadImage(info: PhotoInformation) {
        img = nil
        // Cache된 이미지가 존재하면 해당 이미지를 사용
        if let imageFromCache = imageCache.object(forKey: info.imageName as NSString) {
            self.img = imageFromCache
            return
        }
        indicator.startAnimating()
        let image = configLocalStorage.loadImageFromDocumentDirectory(imageName: info.imageName)
        guard let image = image else {
            indicator.stopAnimating()
            return
        }
        // 캐싱(캐시에 저장)
        self.imageCache.setObject(image, forKey: info.imageName as NSString)
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.ImageView.image = image
        }
    }
}
