//
//  getCurrentWindow.swift
//  RankFit
//
//  Copyright (c) 2023 oasis444. All right reserved.
//

import Foundation
import UIKit

// 현재 보이는 뷰 컨트롤러 가져오기
extension UIResponder {
    func getCurrentViewController() -> UIViewController? {
        let vc = UIWindow().visibleViewController()
        return vc
    }
}
