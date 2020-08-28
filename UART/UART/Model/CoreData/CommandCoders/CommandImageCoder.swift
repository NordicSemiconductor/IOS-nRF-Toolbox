//
//  CommandImageCoder.swift
//  UART
//
//  Created by Nick Kibysh on 27/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core

class CommandImageCoder: NSObject {
    
    private struct Key {
        static let modernName = "CommandImageCoder.Key.modernName"
        static let legacyName = "CommandImageCoder.Key.legacyName"
    }
    
    var icon: CommandImage
    
    func encode(with coder: NSCoder) {
        coder.encode(icon.systemIcon?.name, forKey: Key.modernName)
        coder.encode(icon.name, forKey: Key.legacyName)
    }

    init(icon: CommandImage) {
        self.icon = icon
    }
    
    required init?(coder: NSCoder) {
        guard let legacyName = coder.decodeObject(forKey: Key.legacyName) as? String else {
            return nil
        }

        let modernIcon = (coder.decodeObject(forKey: Key.modernName) as? String).flatMap { ModernIcon(name: $0) }
        self.icon = CommandImage(name: legacyName, modernIcon: modernIcon)
    }
    
    
}
