//
//  UARTMacroCommandWrapper.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 09/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class UARTMacroCommandWrapper: NSObject, UARTMacroElement {

    struct CodingKey {
        static let repeatCount = "CodingKey.repeatCount"
        static let timeInterval = "CodingKey.timeInterval"
        static let command = "CodingKey.command"
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.repeatCount, forKey: CodingKey.repeatCount)
        coder.encode(self.timeInterval, forKey: CodingKey.repeatCount)
        coder.encode(self.command, forKey: CodingKey.command)
    }
    
    required init?(coder: NSCoder) {
        self.repeatCount = coder.decodeInteger(forKey: CodingKey.repeatCount)
        self.timeInterval = coder.decodeInteger(forKey: CodingKey.timeInterval)
        self.command = coder.decodeObject(forKey: CodingKey.command) as! UARTCommandModel
    }
    
    init(command: UARTCommandModel, repeatCount: Int = 0, timeInterval: Int = 0) {
        self.repeatCount = repeatCount
        self.timeInterval = timeInterval
        self.command = command
    }
    
    var repeatCount: Int
    var timeInterval: Int
    var command: UARTCommandModel
}
