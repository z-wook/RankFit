//
//  RevokeViewModel.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/29.
//

import Foundation
import FirebaseFirestore
import Alamofire
import Combine
import CoreData

final class RevokeViewModel {
    
    let deleteSubject = PassthroughSubject<Bool, Never>()
    let allClearSubject = PassthroughSubject<Bool, Never>()
    var subscriptions = Set<AnyCancellable>()
    let UID = saveUserData.getKeychainStringValue(forKey: .UID) ?? ""
    
    init() {
        deleteSubject.receive(on: RunLoop.main).sink { result in
            if result { // firestore 삭제 성공
                print("서버, Firebase 모든 정보 삭제 성공")
                self.removeAll_File()
                self.removeAll_CoreData()
                self.removeAll_Keychain()
                self.removeAll_UserDefaults()
                self.allClearSubject.send(true)
            } else {
                self.allClearSubject.send(false)
            }
        }.store(in: &subscriptions)
    }
    
    func initiateWithdrawal() {
        // 1. 서버 데이터 삭제
        // 2. firebase 데이터 삭제 / Storage, Firestore, Auth
        // 3. 앱 데이터 삭제 / FileManager, CoreData, UserDefaults
        removeServerData()
    }
    
    private func removeServerData() {
        // 서버 데이터 삭제 시작
        let parameters: Parameters = [
            "userID": UID
        ]
        AF.request("http://mate.gabia.io/Leave.php", method: .post, parameters: parameters).validate(statusCode: 200..<300).responseString { response in
            guard let responseBody = response.value else {
                print("result == nil")
                configFirebase.errorReport(type: "RevokeVM.removeServerData", descriptions: "result == nil", server: response.debugDescription)
                self.deleteSubject.send(false)
                return
            }
            if responseBody == "DROP success" {
                print("서버 데이터 삭제 완료")
                // firebase 데이터 삭제 시작
                configFirebase.removeFireStorage(subject: self.deleteSubject)
                return
            } else { // DROP fail
                print("DROP fail")
                configFirebase.errorReport(type: "RevokeVM.removeServerData", descriptions: "DROP fail", server: responseBody.debugDescription)
                self.deleteSubject.send(false)
            }
        }
    }
    
    private func removeAll_File() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? fileManager.removeItem(at: documentDirectory)
    }
    
    private func removeAll_CoreData() {
        let modelName: [String] = ["Aerobic", "Anaerobic", "PhotoInfo"]
        for i in modelName {
            let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
            let context = appDelegate?.persistentContainer.viewContext
            let fetrequest = NSFetchRequest<NSFetchRequestResult>(entityName: i)
            // Batch는 한꺼번에 데이터처리를 할때 사용, 아래의 경우 저장된 데이터를 모두 지우는 것
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetrequest)
            do {
                try context?.execute(batchDeleteRequest)
                print("\(i) 데이터 모두 삭제")
            } catch {
                print(error.localizedDescription)
                configFirebase.errorReport(type: "RevokeVM.removeAll_CoreData", descriptions: error.localizedDescription)
            }
        }
    }
    
    private func removeAll_Keychain() {
        print("Keychain 삭제")
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        SecItemDelete(query as CFDictionary)
    }
    
    private func removeAll_UserDefaults() {
        print("UserDefaults 삭제")
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
}
