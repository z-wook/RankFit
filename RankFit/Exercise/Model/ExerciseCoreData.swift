//
//  ExerciseCoreData.swift
//  RankFit
//
//  Created by 한지욱 on 2022/12/10.
//

import Foundation
import CoreData
import UIKit

final class ExerciseCoreData {
    
    static func saveCoreData(info: AnyHashable) -> Bool {
        print("Save CoreData")
        if let anaerobicInfo = info as? anaerobicExerciseInfo {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Anaerobic", in: context)

            if let entity = entity {
                let object = NSManagedObject(entity: entity, insertInto: context)
                object.setValue(anaerobicInfo.id, forKey: "id")
                object.setValue(anaerobicInfo.exercise, forKey: "exercise")
                object.setValue(anaerobicInfo.tableName, forKey: "tableName")
                object.setValue(anaerobicInfo.date, forKey: "date")
                object.setValue(anaerobicInfo.set, forKey: "set")
                object.setValue(anaerobicInfo.weight, forKey: "weight")
                object.setValue(anaerobicInfo.count, forKey: "count")
                object.setValue(anaerobicInfo.exTime, forKey: "exTime")
                object.setValue(anaerobicInfo.saveTime, forKey: "saveTime")
                object.setValue(anaerobicInfo.done, forKey: "done")

                do {
                    try context.save()
                    return true
                } catch {
                    print("error: " + error.localizedDescription)
                    configFirebase.errorReport(type: "ExerciseCoreData.saveCoreData/Anaerobic", descriptions: error.localizedDescription)
                    return false
                }
            }
        }
        
        if let aerobicInfo = info as? aerobicExerciseInfo {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Aerobic", in: context)
            
            if let entity = entity {
                let object = NSManagedObject(entity: entity, insertInto: context)
                object.setValue(aerobicInfo.id, forKey: "id")
                object.setValue(aerobicInfo.exercise, forKey: "exercise")
                object.setValue(aerobicInfo.tableName, forKey: "tableName")
                object.setValue(aerobicInfo.date, forKey: "date")
                object.setValue(aerobicInfo.distance, forKey: "distance")
                object.setValue(aerobicInfo.time, forKey: "time")
                object.setValue(aerobicInfo.saveTime, forKey: "saveTime")
                object.setValue(aerobicInfo.done, forKey: "done")
                
                do {
                    try context.save()
                    return true
                } catch {
                    print("error: " + error.localizedDescription)
                    configFirebase.errorReport(type: "ExerciseCoreData.saveCoreData/Aerobic", descriptions: error.localizedDescription)
                    return false
                }
            }
        }
        return false
    }
    
    static func fetchCoreData(date: String) -> [AnyHashable] {
        var exerciseInfoList: [AnyHashable] = []
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        do {
            let anaerobicExList = try context.fetch(Anaerobic.fetchRequest()) as! [Anaerobic]
            anaerobicExList.forEach {
                if $0.date == date {
                    let id = $0.id ?? UUID()
                    let exerciseName = $0.exercise ?? ""
                    let tableName = $0.tableName ?? ""
                    let date = $0.date ?? ""
                    let set = $0.set
                    let weight = $0.weight
                    let count = $0.count
                    let exTime = $0.exTime
                    let saveTime = $0.saveTime
                    let done = $0.done

                    let exerciseInfo = anaerobicExerciseInfo(id: id, exercise: exerciseName, tableName: tableName, date: date, set: set, weight: weight, count: count, exTime: exTime, saveTime: saveTime, done: done)
                    exerciseInfoList.append(exerciseInfo)
                }
            }
            
            let aerobicExList = try context.fetch(Aerobic.fetchRequest()) as! [Aerobic]
            aerobicExList.forEach {
                if $0.date == date {
                    let id = $0.id ?? UUID()
                    let exerciseName = $0.exercise ?? ""
                    let tableName = $0.tableName ?? ""
                    let date = $0.date ?? ""
                    let time = $0.time
                    let distance = $0.distance
                    let saveTime = $0.saveTime
                    let done = $0.done

                    let exerciseInfo = aerobicExerciseInfo(id: id, exercise: exerciseName, tableName: tableName, date: date, time: time, distance: distance, saveTime: saveTime, done: done)
                    exerciseInfoList.append(exerciseInfo)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return exerciseInfoList
    }
    
    static func updateCoreData(id: UUID, entityName: String , distance: Double? = nil, time: Int16? = nil, saveTime: Int64 ,done: Bool) -> Bool {
        print("Update CoreData")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id as CVarArg)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            let object = result[0] as! NSManagedObject
            
            switch entityName {
            case "Aerobic":
                object.setValue(distance, forKey: "distance")
                object.setValue(saveTime, forKey: "saveTime")
                object.setValue(time, forKey: "time")
                object.setValue(done, forKey: "done")
                
            case "Anaerobic":
                object.setValue(saveTime, forKey: "saveTime")
                object.setValue(done, forKey: "done")
                
            default: break
            }
            
            try managedContext.save()
            return true
        } catch let error as NSError {
            print("Could not update. \(error.localizedDescription), \(error.userInfo)")
            configFirebase.errorReport(type: "ExerciseCoreData.updateCoreData", descriptions: error.localizedDescription)
            return false
        }
    }
    
    static func deleteCoreData(id: UUID, entityName: String) -> Bool {
        print("Delete CoreData")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id as CVarArg)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            let objectToDelete = result[0] as! NSManagedObject
            managedContext.delete(objectToDelete)
            
            try managedContext.save()
            return true
        } catch let error as NSError {
            print("Could not delete. \(error.localizedDescription), \(error.userInfo)")
            configFirebase.errorReport(type: "ExerciseCoreData.deleteCoreData", descriptions: error.localizedDescription)
            return false
        }
    }
}
