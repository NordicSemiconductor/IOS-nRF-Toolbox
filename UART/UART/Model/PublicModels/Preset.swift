//
//  Preset.swift
//  UART
//
//  Created by Nick Kibysh on 25/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

public struct Preset {
    public var commands: [Command]
    public var name: String
    public var isFavorite: Bool
    
    var storedObject: PresetObject?
    
    public init(commands: [Command], name: String, isFavorite: Bool) {
        self.commands = commands
        self.name = name
        self.isFavorite = isFavorite
    }
    
    init(object: PresetObject) {
        self.storedObject = object
        
        name = object.name ?? ""
        isFavorite = object.isFavorite
        commands = []
    }
}

extension Preset: Equatable {
    public static func == (lhs: Preset, rhs: Preset) -> Bool {
        guard let obj1 = lhs.storedObject, let obj2 = rhs.storedObject else {
            return false
        }
        
        return obj1 == obj2
    }
}
