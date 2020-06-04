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
public class UARTMacro: NSManagedObject {
    
    var elements: [UARTMacroElement] {
        get {
            self.commandsSet.map { $0 as! UARTMacroElement }
        }
        set {
            newValue.forEach(self.addToCommandsSet)
        }
    }
    
    var commands: [UARTCommandModel] {
        elements.compactMap { $0 as? UARTCommandModel }
    }
    
    init(name: String, commands: [UARTMacroElement], preset: UARTPreset, context: NSManagedObjectContext = CoreDataStack.uart.viewContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "UARTMacro", in: context)!
        super.init(entity: entity, insertInto: context)

        self.name = name
        self.elements = commands
        self.preset = preset
    }
    
    static let empty = UARTMacro(name: "", commands: [], preset: .empty)
}
