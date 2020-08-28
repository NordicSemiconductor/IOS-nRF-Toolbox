//
//  DataCommandCoder.swift
//  UART
//
//  Created by Nick Kibysh on 27/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class DataCommandCoder: NSObject, CommandCoding {
    
    private struct Key {
        static let dataKey = "DataCommandCoder.Key.dataKey"
        static let iconKey = "DataCommandCoder.Key.iconKey"
    }
    
    var command: Command { dataCommand }
    let dataCommand: DataCommand
    
    init(dataCommand: DataCommand) {
        self.dataCommand = dataCommand
    }
    
    required init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: Key.dataKey) as? Data, let iconCoder = coder.decodeObject(forKey: Key.iconKey) as? CommandImageCoder else {
            return nil
        }

        self.dataCommand = DataCommand(data: data, image: iconCoder.icon)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(dataCommand.data, forKey: Key.dataKey)
        coder.encode(CommandImageCoder(icon: dataCommand.icon), forKey: Key.iconKey)
    }
    
}
