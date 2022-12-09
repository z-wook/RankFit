//
//  Aerobic+CoreDataProperties.swift
//  
//
//  Created by 한지욱 on 2022/12/10.
//
//

import Foundation
import CoreData


extension Aerobic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Aerobic> {
        return NSFetchRequest<Aerobic>(entityName: "Aerobic")
    }

    @NSManaged public var date: String?
    @NSManaged public var distance: Double
    @NSManaged public var done: Bool
    @NSManaged public var exercise: String?
    @NSManaged public var id: UUID?
    @NSManaged public var saveTime: String?
    @NSManaged public var time: Int16

}
