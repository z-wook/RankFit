//
//  Anaerobic+CoreDataProperties.swift
//  
//
//  Created by 한지욱 on 2022/12/10.
//
//

import Foundation
import CoreData


extension Anaerobic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Anaerobic> {
        return NSFetchRequest<Anaerobic>(entityName: "Anaerobic")
    }

    @NSManaged public var count: Int16
    @NSManaged public var date: String?
    @NSManaged public var done: Bool
    @NSManaged public var exercise: String?
    @NSManaged public var id: UUID?
    @NSManaged public var saveTime: String?
    @NSManaged public var set: Int16
    @NSManaged public var weight: Float

}
