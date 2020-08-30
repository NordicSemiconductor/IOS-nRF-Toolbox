//
//  EmptyCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

public struct EmptyCommand: Command {
    public let data: Data
    public let icon: CommandImage
    public let title: String
    
    public init() {
        data = Data()
        icon = CommandImage.empty
        title = ""
    }
}
