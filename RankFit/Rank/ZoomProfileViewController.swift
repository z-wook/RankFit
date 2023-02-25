//
//  ZoomProfileViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/18.
//

import UIKit

class ZoomProfileViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var profileImage: UIImageView!
    
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    func configure() {
        scrollView.delegate = self
        profileImage.image = image
    }
    
    @IBAction func closeBtn(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension ZoomProfileViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.profileImage
    }
}
