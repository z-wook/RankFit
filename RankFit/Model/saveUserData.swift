//
//  saveUserData.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/09.
//

import Foundation
import SwiftKeychainWrapper

final class saveUserData {
    /**
     # (E) KeychainKey
     - Authors: han
     */
    enum KeychainKey: String {
        case Email
        case UserID
        case NickName
        case Gender
        case Age
        case Weight
    }
    
    /**
     # setKeychain
     - parameters:
        - value : 저장할 값(String)
        - keychainKey : 저장할 value의  Key - (E) Common.KeychainKey
     - Authors: han
     - Note: 키체인에 값을 저장하는 공용 함수
     */
    static func setKeychain(_ value: String, forKey keychainKey: KeychainKey) {
        KeychainWrapper.standard.set(value, forKey: keychainKey.rawValue)
    }
    
    /**
     # setKeychain
     - parameters:
        - value : 저장할 값(Int)
        - keychainKey : 저장할 value의  Key - (E) Common.KeychainKey
     - Authors: han
     - Note: 키체인에 값을 저장하는 공용 함수
     */
    static func setKeychain(_ value: Int, forKey keychainKey: KeychainKey) {
        KeychainWrapper.standard.set(value, forKey: keychainKey.rawValue)
    }

    /**
     # getKeychainValue
     - parameters:
        - keychainKey : 반환할 value의 Key(String?) - (E) Common.KeychainKey
     - Authors: han
     - Note: 키체인 값을 반환하는 공용 함수
     */
    static func getKeychainStringValue(forKey keychainKey: KeychainKey) -> String? {
        let returnValue: String? = KeychainWrapper.standard.string(forKey: keychainKey.rawValue)
        return returnValue
    }
    
    /**
     # getKeychainValue
     - parameters:
        - keychainKey : 반환할 value의 Key(Int?) - (E) Common.KeychainKey
     - Authors: han
     - Note: 키체인 값을 반환하는 공용 함수
     */
    static func getKeychainIntValue(forKey keychainKey: KeychainKey) -> Int? {
        let returnValue: Int? = KeychainWrapper.standard.integer(forKey: keychainKey.rawValue)
        return returnValue
    }
    
    /**
     # removeKeychain
     - parameters:
        - keychainKey : 삭제할 value의  Key - (E) Common.KeychainKey
     - Authors: han
     - Note: 키체인 값을 삭제하는 공용 함수
     */
    static func removeKeychain(forKey keychainKey: KeychainKey) {
//        let removeSuccessful: Bool
        KeychainWrapper.standard.removeObject(forKey: keychainKey.rawValue)
    }
}
