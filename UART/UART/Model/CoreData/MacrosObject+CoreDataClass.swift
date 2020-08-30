//
//  MacrosObject+CoreDataClass.swift
//  
//
//  Created by Nick Kibysh on 26/08/2020.
//
//

import Foundation
import CoreData

@objc(MacrosObject)
class MacrosObject: NSManagedObject {
    init(commands: [NSObject], name: String, colorName: String, context: NSManagedObjectContext) {
        let entity = Self.getEntity(context: context)!
        super.init(entity: entity, insertInto: context)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
