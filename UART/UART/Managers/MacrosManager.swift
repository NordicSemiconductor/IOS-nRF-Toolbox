//
//  MacrosManager.swift
//  UART
//
//  Created by Nick Kibysh on 25/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core
import CoreData

open class MacrosManager {
    
    let storage: CoreDataStack
    
    init(stack: CoreDataStack = .uart) {
        storage = stack
    }
    
    public init() {
        storage = .uart
    }
    
    open func loadMacros() throws -> [Macros] {
        let request: NSFetchRequest<MacrosObject> = MacrosObject.fetchRequest()
        
        let objects = try storage.viewContext.fetch(request)
        return objects.map { MacrosConverter(stack: self.storage).convert(object: $0) }
    }
    
    open func save(macros: Macros) throws -> Macros {
        let obj: MacrosObject = macros.macrosObject ?? {
            let object = MacrosConverter(stack: storage).convert(model: macros)
            storage.viewContext.insert(object)
            return object
        }()
        
        obj.name = macros.name
        obj.colorName = macros.color.name.rawValue
        obj.commandSet = macros.elements.compactMap { MacrosElementContainerCoder(container: $0) }
        
        var newMacros = macros
        newMacros.macrosObject = obj
        
        try! storage.viewContext.save()
        
        return newMacros
    }
    
    open func dupplicate(macros: Macros, name: String?) -> Macros {
        var newMacros = macros
        newMacros.name = name ?? macros.name + " copy"
        newMacros.macrosObject = nil
        
        return newMacros
    }
}
