//
//  PhotoCoreData.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/21.
//

import Foundation
import CoreData
import UIKit

final class PhotoCoreData {
    
    static func profileInfo_exist_inCoreData() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "PhotoInfo")
        fetchRequest.predicate = NSPredicate(format: "imageName = %@", "profileImage.jpeg" as CVarArg)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if result.isEmpty { return false } // Profile 정보 없음
            else { return true }               // Profile 정보 있음
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
            configFirebase.errorReport(type: "PhotoCoreData.profileInfo_exist_inCoreData", descriptions: error.localizedDescription)
            return false
        }
    }
    
    static func saveCoreData(info: PhotoInfomation) -> Bool {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "PhotoInfo", in: context)
        if let entity = entity {
            let object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(info.imageName, forKey: "imageName")
            object.setValue(info.saveTime, forKey: "saveTime")
            
            do {
                try context.save()
                print("Save CoreData")
                return true
            } catch {
                print("error: \(error.localizedDescription)")
                configFirebase.errorReport(type: "PhotoCoreData.saveCoreData", descriptions: error.localizedDescription)
                return false
            }
        }
        return false
    }
    
    static func fetchCoreData() -> [PhotoInfomation] {
        var photoInfoList: [PhotoInfomation] = []
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let anaerobicExList = try context.fetch(PhotoInfo.fetchRequest()) as! [PhotoInfo]
            anaerobicExList.forEach {
                let imgName = $0.imageName ?? "이름 없음"
                let saveTime = $0.saveTime
                
                let photoInfo = PhotoInfomation(imageName: imgName, saveTime: saveTime)
                photoInfoList.append(photoInfo)
            }
        } catch {
            print("error: \(error.localizedDescription)")
            configFirebase.errorReport(type: "PhotoCoreData.fetchCoreData", descriptions: error.localizedDescription)
        }
        let sortedList = photoInfoList.sorted { prev, next in
            return prev.saveTime > next.saveTime
        }
        return sortedList
    }
    
    static func deleteCoreData(imageName: String) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "PhotoInfo")
        fetchRequest.predicate = NSPredicate(format: "imageName = %@", imageName as CVarArg)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            let objectToDelete = result[0] as! NSManagedObject
            managedContext.delete(objectToDelete)
            
            try managedContext.save()
            print("Core Data에서 이미지 정보 삭제 성공")
            return true
        } catch let error as NSError {
            print("Core Data에서 이미지 정보 삭제 실패: \(error), \(error.userInfo)")
            configFirebase.errorReport(type: "PhotoCoreData.deleteCoreData", descriptions: error.localizedDescription)
            return false
        }
    }
}
