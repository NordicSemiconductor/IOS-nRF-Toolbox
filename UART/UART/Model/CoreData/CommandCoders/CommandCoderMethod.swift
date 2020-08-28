//
//  CommandCoderMethod.swift
//  UART
//
//  Created by Nick Kibysh on 27/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core

enum CommandCoderMethod {
    static func coder(for command: Command) -> CommandCoding {
        switch command {
        case let textCommand as TextCommand:
            return TextCommandCoder(textCommand: textCommand)
        case let dataCommand as DataCommand:
            return DataCommandCoder(dataCommand: dataCommand)
        case is EmptyCommand:
            return EmptyCommandCoder()
        default:
            SystemLog.fault("Unsupported command type", category: .uart)
        }
    }
}
