//
//  MacrosElementCoder.swift
//  UART
//
//  Created by Nick Kibysh on 28/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class MacrosElementContainerCoder: NSObject, NSCoding {
    
    private enum Key {
        static let delay = "MacrosElementCoderCoder.Key.delay"
        static let commandContainer = "MacrosElementCoderCoder.Key.commandContainer"
    }
    
    let container: MacrosElement
    
    func encode(with coder: NSCoder) {
        switch container {
        case .commandContainer(let container):
            let containerCoder = MacrosCommandContainerCoder(container: container)
            coder.encode(containerCoder, forKey: Key.commandContainer)
        case .delay(let ti):
            coder.encode(ti, forKey: Key.delay)
        }
    }
    
    required init?(coder: NSCoder) {
        if let container = coder.decodeObject(forKey: Key.commandContainer) as? MacrosCommandContainerCoder {
            self.container = .commandContainer(container.container)
        } else {
            let ti = coder.decodeDouble(forKey: Key.delay)
            self.container = .delay(ti)
        }
    }
    
    init(container: MacrosElement) {
        self.container = container
    }
    
}
