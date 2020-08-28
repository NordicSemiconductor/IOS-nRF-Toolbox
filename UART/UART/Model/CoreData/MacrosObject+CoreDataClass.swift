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
    init(commands: [MacrosElement], name: String, color: Color, context: NSManagedObjectContext) {
        let entity = Self.getEntity(context: context)!
        super.init(entity: entity, insertInto: context)


        self.name = name
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
