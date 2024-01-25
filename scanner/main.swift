//
//  main.swift
//  scanner
//
//  Created by Nick Kibysh on 25/01/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

/*
To discover the UUID of the peripheral you want to connect to, run the scanner app and copy the UUID from the console. 
 */
let peripheralUuidString = ""
let peripheral = try await scanAndConnect(to: peripheralUuidString)
print("Connected \(peripheral.name ?? "unnamed") peripheral")
