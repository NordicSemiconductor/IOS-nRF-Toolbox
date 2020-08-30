//
//  TextCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

public struct TextCommand: Command {
    
    public let icon: CommandImage
    public let title: String
    public var eol: EOL
    
    public var data: Data {
        title.data(using: .utf8)!
    }
    
    public init(text: String, image: CommandImage, eol: EOL = .cr) {
        self.title = text
        self.icon = image
        self.eol = eol
    }
}
