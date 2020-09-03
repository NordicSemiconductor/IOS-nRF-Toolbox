//
// Created by Nick Kibysh on 28/08/2020.
// Copyright (c) 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class MacrosCommandContainerCoder: NSObject, NSCoding {
    
    private struct Key {
        static let repeatCont = "MacrosCommandContainerCoder.Key.repeatCont"
        static let delay = "MacrosCommandContainerCoder.Key.delay"
        static let command = "MacrosCommandContainerCoder.Key.command"
    }
    
    let container: MacrosCommandContainer
    
    func encode(with coder: NSCoder) {
        
        coder.encode(Int32(container.delay), forKey: Key.delay)
        coder.encode(Int32(container.repeatCount), forKey: Key.repeatCont)
        coder.encode(CommandCoderMethod.coder(for: container.command), forKey: Key.command)
    }
    
    required init?(coder: NSCoder) {
        guard let commandCoder = coder.decodeObject(forKey: Key.command) as? CommandCoding else {
            fatalError()
            return nil
        }
        
        let delay = coder.decodeInt32(forKey: Key.delay)
        let repeatCont = coder.decodeInt32(forKey: Key.repeatCont)
        
        self.container = MacrosCommandContainer(command: commandCoder.command, repeatCount: Int(repeatCont), delay: Int(delay))
    }
    
    init(container: MacrosCommandContainer) {
        self.container = container
    }
}
