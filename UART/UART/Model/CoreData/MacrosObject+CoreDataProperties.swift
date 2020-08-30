//
//  MacrosObject+CoreDataProperties.swift
//  
//
//  Created by Nick Kibysh on 26/08/2020.
//
//

import Foundation
import CoreData


extension MacrosObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MacrosObject> {
        return NSFetchRequest<MacrosObject>(entityName: "UARTMacro")
    }

    @NSManaged public var colorName: String
    @NSManaged public var commandSet: [NSObject]
    @NSManaged public var name: String

}
