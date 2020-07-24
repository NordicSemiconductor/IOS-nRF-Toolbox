//
//  UARTMacrosBuilder.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class UARTMacrosBuilder: UARTCommandSendManager {
    var commands: [UARTCommandModel] = []
    
    func send(command aCommand: UARTCommandModel) {
        guard !(aCommand is EmptyModel) else {
            return 
        }
        commands.append(aCommand)
    }
    
    func reset() {
        self.commands.removeAll()
    }
}
