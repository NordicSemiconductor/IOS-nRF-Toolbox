//
//  MacrosConverter.swift
//  UART
//
//  Created by Nick Kibysh on 28/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core

struct MacrosConverter: ModelConverter {
    typealias M = Macros
    typealias O = MacrosObject
    
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = .uart) {
        self.stack = stack
    }
    
    func convert(model: Macros) -> MacrosObject {
        let name = model.name
        let colorName = model.color.name.rawValue
        let elements = model.elements.map { MacrosElementContainerCoder(container: $0) as NSObject }
        
        let obj = MacrosObject(commands: elements, name: name, colorName: colorName, context: stack.viewContext)
        return obj
    }
    
    func convert(object: MacrosObject) -> Macros {
        let elemests = object.commandSet
            .compactMap { $0 as? MacrosElementContainerCoder }
            .map { $0.container }
        let name = object.name
        let color = Color(colorNameString: object.colorName) ?? Color.nordic
        
        return Macros(elements: elemests, name: name, color: color, macrosObject: object)
    }
}
