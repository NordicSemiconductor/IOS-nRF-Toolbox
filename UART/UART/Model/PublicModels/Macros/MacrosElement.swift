//
// Created by Nick Kibysh on 28/08/2020.
// Copyright (c) 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

public enum MacrosElement {
    case delay(TimeInterval)
    case commandContainer(MacrosCommandContainer)
}

extension MacrosElement: Equatable {
    public static func == (lhs: MacrosElement, rhs: MacrosElement) -> Bool {
        
        if case .delay(let lti) = lhs, case .delay(let rti) = rhs {u
            return lti == rti
        } else if case .commandContainer(let lCommand) = lhs, case .commandContainer(let rCommand) = rhs {
            return CommandComparator.compare(lCommand: lCommand.command, rCommand: rCommand.command)
                && lCommand.delay == rCommand.delay
                && lCommand.repeatCount == rCommand.repeatCount
        }
        
        return false
    }
    
    
}
