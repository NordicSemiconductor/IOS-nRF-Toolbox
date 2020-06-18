//
//  UARTPreset+CoreDataProperties.swift
//  
//
//  Created by Nick Kibish on 18.06.2020.
//
//

import Foundation
import CoreData


extension UARTPreset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UARTPreset> {
        return NSFetchRequest<UARTPreset>(entityName: "UARTPreset")
    }

    @NSManaged public var isFavorite: Bool
    @NSManaged public var name: String?

}
