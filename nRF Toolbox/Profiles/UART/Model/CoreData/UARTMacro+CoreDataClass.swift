//
//  UARTMacro+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 03.06.2020.
//
//

import Foundation
import CoreData

@objc(UARTMacro)
class UARTMacro: NSManagedObject {
    
    var commands: [UARTMacroElement] = []
    
    init(name: String, commands: [UARTMacroElement], preset: UARTPreset, context: NSManagedObjectContext? = CoreDataStack.uart.viewContext) {
        
        if let entity = context.flatMap({ Self.getEntity(context: $0) }) {
            super.init(entity: entity, insertInto: context)
        } else {
            super.init()
        }

        self.name = name
        self.preset = preset
    }
    
    static let empty = UARTMacro(name: "", commands: [], preset: .default)
    
    func replaceCommandsSet(at: Int, with element: UARTMacroElement) {
        
    }
}
