//
//  PhotoInfo+CoreDataProperties.swift
//  
//
//  Created by 한지욱 on 2023/01/21.
//
//

import Foundation
import CoreData


extension PhotoInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoInfo> {
        return NSFetchRequest<PhotoInfo>(entityName: "PhotoInfo")
    }

    @NSManaged public var imageName: String?
    @NSManaged public var saveTime: Int64

}
