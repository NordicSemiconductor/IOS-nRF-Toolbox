//
//  UARTMacroCommandWrapper.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 09/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class UARTMacroCommandWrapper: NSObject, UARTMacroElement {
    func encode(with coder: NSCoder) {
        
    }
    
    required init?(coder: NSCoder) {
        repeatCount = 1
        timeInterval = 100
        command = TextCommand(text: "Stop", image: .stop)
    }
    
    override init() {
        repeatCount = 1
        timeInterval = 100
        command = TextCommand(text: "Stop", image: .stop)
    }
    
    var repeatCount: Int
    var timeInterval: Int
    var command: UARTCommandModel
}
