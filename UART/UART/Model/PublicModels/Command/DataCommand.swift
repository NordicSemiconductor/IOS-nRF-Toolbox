//
//  DataCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

public struct DataCommand: Command {
    public let data: Data
    public let icon: CommandImage
    
    public var title: String {
        "0x" + data.hexString
    }
    
    public init(data: Data, image: CommandImage) {
        self.data = data
        self.icon = image
    }
}
