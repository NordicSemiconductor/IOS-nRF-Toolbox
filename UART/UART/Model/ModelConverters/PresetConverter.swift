//
//  PresetConverter.swift
//  UART
//
//  Created by Nick Kibysh on 28/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core

struct PresetConverter: ModelConverter {
    typealias M = Preset
    typealias O = PresetObject
    
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = .uart) {
        self.stack = stack
    }
    
    func convert(model: Preset) -> PresetObject {
        let commands = model.commands.compactMap { CommandCoderMethod.coder(for: $0) as? NSObject }
        let preset = PresetObject.init(commands: commands, name: model.name, isFavorite: model.isFavorite, context: stack.viewContext)
        return preset 
    }
    
    func convert(object: PresetObject) -> Preset {
        let commands = object.commandSet?
            .compactMap { $0 as? CommandCoding }
            .map { $0.command } ?? []
        let name = object.name ?? ""
        
        return Preset(commands: commands, name: name, isFavorite: object.isFavorite)
    }
}
