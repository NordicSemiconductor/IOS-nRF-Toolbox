//
//  ZephyrPacket.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 05/11/2021.
//  Copyright © 2021 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct ZephyrPacket: DFUPacket {
    var url: URL
    var firmware: McuMgrFirmware
    
    var name: String {
        return url.lastPathComponent
    }
}
