//
//  defaultViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/12.
//

import UIKit
import SafariServices

class defaultViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    var readingText: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        textView.text = readingText
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .link
    }
    
    func configure(type: String) {
        if type == "이용약관" {
            navigationItem.title = "이용약관"
            readingText = Provision().provision
        } else if type == "이용규칙" {
            navigationItem.title = "이용규칙"
            readingText = Rule().rule
        } else if type == "저작권" {
            navigationItem.title = "저작권"
            readingText = Copyright().copyright
        } else { // 랭킹 도움말
            navigationItem.title = "랭킹 도움말"
            readingText = Rank_Descriptions().descriptions
        }
    }
}

extension defaultViewController {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let vc = SFSafariViewController(url: URL)
        present(vc, animated: true)
        return false
    }
}
