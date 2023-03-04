//
//  NoticeDetailViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/02/26.
//

import UIKit

class NoticeDetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    
    var info: notification!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    private func configure() {
        navigationItem.title = "공지사항"
        titleLabel.text = info.title
        contentView.text = info.content
        dateLabel.text = info.register_day
    }
}
