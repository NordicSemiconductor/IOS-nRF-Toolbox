//
//  CommandComparator.swift
//  UART
//
//  Created by Nick Kibysh on 31/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct CommandComparator {
    static func compare(lCommand: Command, rCommand: Command) -> Bool {
        switch (lCommand, rCommand) {
        case (let ltCommand as TextCommand, let rtCommand as TextCommand):
            return ltCommand.title == rtCommand.title
                && ltCommand.eol == rtCommand.eol
        case (let ldCommand as DataCommand, let rdCommand as DataCommand):
            return ldCommand.data == rdCommand.data
        case (is EmptyCommand, is EmptyCommand):
            return true
        default:
            return false
        }
    }
}
