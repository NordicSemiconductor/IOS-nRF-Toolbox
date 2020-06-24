//
//  UARTPreset+CoreDataProperties.swift
//  
//
//  Created by Nick Kibysh on 23/06/2020.
//
//

import Foundation
import CoreData


extension UARTPreset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UARTPreset> {
        return NSFetchRequest<UARTPreset>(entityName: "UARTPreset")
    }

    @NSManaged var isFavorite: Bool
    @NSManaged var name: String?
    @NSManaged var commandSet: [NSObject]!

}
