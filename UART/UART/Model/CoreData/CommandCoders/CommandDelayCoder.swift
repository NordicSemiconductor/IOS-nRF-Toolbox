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
        coder.encode(container.delay, forKey: Key.delay)
        coder.encode(container.repeatCount, forKey: Key.repeatCont)
        coder.encode(container.command, forKey: Key.command)
    }
    
    required init?(coder: NSCoder) {
        guard let delay = coder.decodeObject(forKey: Key.delay) as? Int,
            let command = coder.decodeObject(forKey: Key.command) as? Command,
            let repeatCont = coder.decodeObject(forKey: Key.repeatCont) as? Int else {
                return nil
        }
        
        self.container = MacrosCommandContainer(command: command, repeatCount: repeatCont, delay: delay)
    }
    
    init(container: MacrosCommandContainer) {
        self.container = container
    }
}
