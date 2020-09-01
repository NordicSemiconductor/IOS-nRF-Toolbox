//
//  PresetObject+CoreDataProperties.swift
//  
//
//  Created by Nick Kibysh on 26/08/2020.
//
//

import Foundation
import CoreData


extension PresetObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PresetObject> {
        return NSFetchRequest<PresetObject>(entityName: "PresetObject")
    }

    @NSManaged public var commandSet: [NSObject]?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var name: String?

}
