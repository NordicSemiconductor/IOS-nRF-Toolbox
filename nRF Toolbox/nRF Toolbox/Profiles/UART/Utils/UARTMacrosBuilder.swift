//
//  UARTMacrosBuilder.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import UART

class UARTMacrosBuilder: UARTCommandSendManager {
    var commands: [Command] = []
    
    func send(command aCommand: Command) {
        guard !(aCommand is EmptyCommand) else {
            return 
        }
        commands.append(aCommand)
    }
    
    func reset() {
        self.commands.removeAll()
    }
}
