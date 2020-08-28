//
//  PresetObject+CoreDataClass.swift
//  
//
//  Created by Nick Kibysh on 26/08/2020.
//
//

import Foundation
import CoreData

@objc(PresetObject)
class PresetObject: NSManagedObject {
    init(commands: [NSObject], name: String, isFavorite: Bool = false, context: NSManagedObjectContext) {
        let entity = Self.getEntity(context: context)!
        super.init(entity: entity, insertInto: context)
        
        self.name = name
        self.isFavorite = isFavorite
        self.commandSet = commands
    }
}
