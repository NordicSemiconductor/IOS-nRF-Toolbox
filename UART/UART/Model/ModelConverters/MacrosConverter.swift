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
        fatalError()
    }
    
    func convert(object: MacrosObject) -> Macros {
        fatalError()
    }
}
