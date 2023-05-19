//
//  NoticeVC.swift
//  RankFit
//
//  Copyright (c) 2023 oasis444. All right reserved.
//

import UIKit

class NoticeVC: UIViewController {

    @IBOutlet weak var noticeView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    var noticeContents: (title: String, detail: String, date: String)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        noticeView.layer.cornerRadius = 10
        confirmButton.layer.cornerRadius = 10
        view.backgroundColor = .black.withAlphaComponent(0.5)
        
        guard let noticeContent = noticeContents else { return }
        titleLabel.text = noticeContent.title
        detailLabel.text = noticeContent.detail
        dateLabel.text = noticeContent.date
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
