//
//  UARTMacroTimeInterval.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 14/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class UARTMacroTimeInterval: NSObject, NSCoding, UARTMacroElement {
    
    private static let tiKey = "UARTMacroTimeInterval.TimeInterval"
    var timeInterval: TimeInterval = 0.1
    
    func encode(with coder: NSCoder) {
        coder.encode(timeInterval, forKey: Self.tiKey)
    }
    
    required init?(coder: NSCoder) {
        timeInterval = coder.decodeDouble(forKey: Self.tiKey)
    }

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    init(milliseconds: Int) {
        self.timeInterval = Double(milliseconds) / 1000.0
    }

}
