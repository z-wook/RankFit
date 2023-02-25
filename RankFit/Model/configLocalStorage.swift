//
//  configLocalStorage.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/19.
//

import Foundation
import UIKit
import Combine

final class configLocalStorage {
    
    // 로컬에 이미지 저장
    static func saveImageToLocal(imageName: String, imgData: Data, subject: PassthroughSubject<String, Never>) {
        // 1. 이미지를 저장할 경로를 설정해줘야함 - Document 폴더, File 관련된건 Filemanager가 관리함(싱글톤 패턴)
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        // 2. 이미지 파일 이름 & 최종 경로 설정
        let imageURL = documentDirectory.appendingPathComponent(imageName + ".jpeg")
        
        // 3. 이미지 저장: 동일한 경로에 이미지를 저장하게 될 경우, 덮어쓰기하는 경우
        // 3-1. 이미지 경로 여부 확인
        if FileManager.default.fileExists(atPath: imageURL.path) {
            // 3-2. 이미지가 존재한다면 기존 경로에 있는 이미지 삭제
            do {
                try FileManager.default.removeItem(at: imageURL)
                print("로컬에서 이미지 삭제 완료")
            } catch {
                print("로컬에서 이미지 삭제 실패")
                configFirebase.errorReport(type: "configLocalStorage.saveImageToLocal", descriptions: error.localizedDescription)
            }
        }
        // 4. 이미지를 도큐먼트에 저장
        // 파일을 저장하는 등의 행위는 조심스러워야하기 때문에 do try catch 문을 사용
        do {
            try imgData.write(to: imageURL)
            print("로컬에 이미지 저장 완료")
            subject.send(imageName + ".jpeg")
        } catch {
            print("로컬에 이미지 저장 실패")
            print("error: " + error.localizedDescription)
            configFirebase.errorReport(type: "configLocalStorage.saveImageToLocal", descriptions: error.localizedDescription)
            subject.send("false")
        }
    }
    
    // 로컬에서 이미지 삭제
    static func deleteImageFromDocumentDirectory(imageName: String) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let imageURL = documentDirectory.appendingPathComponent(imageName)
        if FileManager.default.fileExists(atPath: imageURL.path) {
            do {
                try FileManager.default.removeItem(at: imageURL)
                print("Document에서 이미지 삭제 완료")
            } catch {
                print("Document에서 이미지 삭제 실패")
                configFirebase.errorReport(type: "configLocalStorage.deleteImageFromDocumentDirectory", descriptions: error.localizedDescription)
            }
        }
    }
    
    // 로컬에서 이미지 불러오기
    static func loadImageFromDocumentDirectory(imageName: String) -> UIImage? {
        // 1. 도큐먼트 폴더 경로가져오기
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let path = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        var IMG: UIImage?
        if let directoryPath = path.first {
            // 2. 이미지 URL 찾기
            let imageURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(imageName)
            
            // 3. UIImage로 불러오기
            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                return nil
            }
            IMG = image
        }
        return IMG
    }
}
