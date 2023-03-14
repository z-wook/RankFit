//
//  AskViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/03/06.
//

import UIKit
import Combine

class AskViewController: UIViewController {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var inputBox: UITextView!
    @IBOutlet weak var textLimit: UILabel!
    @IBOutlet weak var askBtn: UIButton!
    
    let askSubject = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    let placeHolder = "문의할 내용과 답변 받을 이메일을 입력해 주세요."
    var screenHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        bind()
    }

    @IBAction func sendAsk(_ sender: UIButton) {
        guard let ask = inputBox.text else { return }
        configFirebase.ask(Ask: ask, subject: askSubject)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension AskViewController {
    private func configure() {
        navigationItem.title = "문의하기"
        inputBox.layer.cornerRadius = 20
        inputBox.text = placeHolder
        inputBox.textColor = .label
        inputBox.delegate = self
        askBtn.backgroundColor = .darkGray
        askBtn.layer.cornerRadius = 20
        askBtn.isEnabled = false
        // 뷰 전체 높이 길이
        let screenHeight = UIScreen.main.bounds.size.height
        self.screenHeight = screenHeight
        setKeyboardObserver()
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if self.view.window?.frame.origin.y == 0 {
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                UIView.animate(withDuration: 1) {
                    if self.screenHeight == 568 { // 4 inch
                        self.view.window?.frame.origin.y -= keyboardHeight / 2 + 40
                    } else if self.screenHeight == 667 { // 4.7 inch
                        self.view.window?.frame.origin.y -= keyboardHeight / 2 + 20
                    } else {
                        self.view.window?.frame.origin.y -= keyboardHeight / 2
                    }
                }
            }
        }
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        if self.view.window?.frame.origin.y != 0 {
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                UIView.animate(withDuration: 1) {
                    if self.screenHeight == 568 { // 4 inch
                        self.view.window?.frame.origin.y += keyboardHeight / 2 + 40
                    } else if self.screenHeight == 667 { // 4.7 inch
                        self.view.window?.frame.origin.y += keyboardHeight / 2 + 20
                    } else {
                        self.view.window?.frame.origin.y += keyboardHeight / 2
                    }
                    
                }
            }
        }
    }
    
    private func bind() {
        askSubject.receive(on: RunLoop.main).sink { result in
            if result {
                self.showAlert(title: "문의사항 접수 완료")
            } else {
                self.showAlert(title: "문의사항 접수 실패", message: "잠시 후 다시 문의해 주세요.")
            }
        }.store(in: &subscriptions)
    }
    
    private func updateCountLabel(characterCount: Int) {
        DispatchQueue.main.async {
            self.textLimit.text = "\(characterCount) / 300"
        }
    }
    
    private func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
}

extension AskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if inputBox.text == placeHolder {
            inputBox.text = nil
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if inputBox.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputBox.text = placeHolder
            askBtn.isEnabled = false
            askBtn.backgroundColor = .darkGray
        } else {
            askBtn.isEnabled = true
            askBtn.backgroundColor = .systemIndigo
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            updateCountLabel(characterCount: 0)
            askBtn.isEnabled = false
            askBtn.backgroundColor = .darkGray
        } else {
            askBtn.isEnabled = true
            askBtn.backgroundColor = .systemIndigo
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let inputString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let oldString = textView.text, let newRange = Range(range, in: oldString) else { return true }
        let newString = oldString.replacingCharacters(in: newRange, with: inputString).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let characterCount = newString.count
        guard characterCount <= 300 else { return false }
        updateCountLabel(characterCount: characterCount)
        
        return true
    }
}