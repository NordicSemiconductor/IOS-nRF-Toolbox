//
//  CommandCoding.swift
//  UART
//
//  Created by Nick Kibysh on 27/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol CommandCoding: NSObjectProtocol, NSCoding {
    var command: Command { get }
}
