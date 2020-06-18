//
//  UARTMacro+CoreDataProperties.swift
//  
//
//  Created by Nick Kibish on 18.06.2020.
//
//

import Foundation
import CoreData


extension UARTMacro {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UARTMacro> {
        return NSFetchRequest<UARTMacro>(entityName: "UARTMacro")
    }

    @NSManaged public var name: String?
    @NSManaged public var preset: UARTPreset?

}
