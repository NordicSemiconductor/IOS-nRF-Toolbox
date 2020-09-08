//
//  Macros.swift
//  UART
//
//  Created by Nick Kibysh on 25/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

public struct Macros {
    public var elements: [MacrosElement]
    public var name: String
    public var color: Color
    
    var macrosObject: MacrosObject?
    
    public var played: Bool {
        return macrosObject?.played ?? false
    }
    
    public init(elements: [MacrosElement], name: String, color: Color) {
        self.elements = elements
        self.name = name
        self.color = color
        self.macrosObject = nil 
    }
    
    init(elements: [MacrosElement], name: String, color: Color, macrosObject: MacrosObject?) {
        self.elements = elements
        self.name = name
        self.color = color
        self.macrosObject = macrosObject
    }
    
    public static var empty: Macros {
        Macros(elements: [], name: "", color: .nordic, macrosObject: nil)
    }
}

extension Macros: Equatable {
    public static func == (lhs: Macros, rhs: Macros) -> Bool {
        guard let lhsObj = lhs.macrosObject, let rhsObj = rhs.macrosObject else {
            return lhs.name == rhs.name &&
                lhs.color == rhs.color &&
                lhs.elements == rhs.elements
        }
        
        return lhsObj == rhsObj
    }
    
    
}
