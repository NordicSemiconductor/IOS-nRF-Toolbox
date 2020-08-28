//
//  EmptyCommandCoder.swift
//  UART
//
//  Created by Nick Kibysh on 27/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

/// This class is used for coding `EmeptyCommand`
/// # Concept
/// Like other command coders `EmptyCommandCoder` is used for encoding / decoding `EmptyCommand`.
/// `EmptyCommand` does not contain any information. Since that encoding method just encode unique key for that class.
/// On decoding stage the key is checked and if it's not correct the object won't be created and `nil` will be returned.
class EmptyCommandCoder: NSObject, CommandCoding {
    
    private struct Key {
        static let emptyCommand = "EmptyCommandCoder.Key.emptyCommand"
    }
    
    var command: Command { emptyModel }
    let emptyModel = EmptyCommand()
    
    func encode(with coder: NSCoder) {
        coder.encode(Key.emptyCommand, forKey: Key.emptyCommand)
    }
    
    required init?(coder: NSCoder) {
        guard let key = coder.decodeObject(forKey: Key.emptyCommand) as? String, key == Key.emptyCommand else {
            return nil
        }
    }
    
    override init() {
        super.init()
    }
}
