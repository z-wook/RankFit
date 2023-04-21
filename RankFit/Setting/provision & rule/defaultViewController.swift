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
    private var readingText: String!
    private var fontSize: CGFloat = 14
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        textView.text = readingText
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .link
        textView.font = UIFont.systemFont(ofSize: fontSize)
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
        } else if type == "개발진" {
            navigationItem.title = "개발진"
            readingText = Developer().dev
            fontSize = 17
        } else { // 랭킹 도움말
            navigationItem.title = "랭킹 도움말"
            readingText = Rank_Descriptions().descriptions
        }
    }
}

extension defaultViewController {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if navigationItem.title == "개발진" { return false }
        let vc = SFSafariViewController(url: URL)
        present(vc, animated: true)
        return false
    }
}
