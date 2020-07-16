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
        coder.encode(Int32(self.repeatCount), forKey: CodingKey.repeatCount)
        coder.encode(Int32(self.timeInterval), forKey: CodingKey.timeInterval)
        coder.encode(self.command, forKey: CodingKey.command)
    }
    
    required init?(coder: NSCoder) {
        self.repeatCount = Int(coder.decodeInt32(forKey: CodingKey.repeatCount))
        self.timeInterval = Int(coder.decodeInt32(forKey: CodingKey.timeInterval))

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
