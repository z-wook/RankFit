//
//  Photoinformation.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/20.
//

import Foundation

struct PhotoInformation: Codable, Hashable {
    let imageName: String
    let saveTime: Int64
    
    init(imageName: String, saveTime: Int64) {
        self.imageName = imageName
        self.saveTime = saveTime
    }
}
