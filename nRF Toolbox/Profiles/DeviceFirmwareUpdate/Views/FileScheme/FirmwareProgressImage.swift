//
//  FirmwareProgressImage.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

extension UIColor {
    static let firmwareApplication: UIColor = .nordicRed
    static let firmwareBootloader: UIColor = .nordicFall
    static let firmwareSoftDevice: UIColor = .nordicGreen
}

class FirmwareProgressImage: ProgressImage {
    func setParts(with firmware: DFUFirmware, reversed: Bool = false ) {
        var parts = [ProgressPart]()
        
        let application = Int(firmware.size.application)
        let bootloader = Int(firmware.size.bootloader)
        let softDevice = Int(firmware.size.softdevice)
        
        if bootloader > 1 {
            parts.append(ProgressPart(parts: bootloader, color: .firmwareBootloader))
        }
        
        if softDevice > 1 {
            parts.append(ProgressPart(parts: softDevice, color: .firmwareSoftDevice))
        }
        
        if application > 1 {
            parts.append(ProgressPart(parts: application, color: .firmwareApplication))
        }
        
        if reversed {
            parts = parts.reversed()
        }
        
        self.parts = parts
    }
}
