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
    
    public static var empty: Macros {
        Macros(elements: [], name: "", color: .nordic, macrosObject: nil)
    }
}
