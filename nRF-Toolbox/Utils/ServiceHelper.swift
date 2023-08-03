//
//  ServiceHelper.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Bluetooth_Numbers_Database
import SwiftUI
import CoreBluetooth

struct ServiceRepresentation {
    let name: String
    let icon: Image
    let color: Color
    
    init?(identifier: String) {
        guard let service = Service.find(by: identifier) else {
            return nil
        }
        
        switch service {
        case .heartRate:
            icon = Image(systemName: "heart.fill")
            name = Service.heartRate.name
            color = .red
        case .runningSpeedAndCadence:
            icon = Image(systemName: "figure.run")
            name = Service.runningSpeedAndCadence.name
            color = .yellow
        case .weightScale:
            icon = Image(systemName: "scalemass.fill")
            name = Service.weightScale.name
            color = .green
        default:
            return nil
        }
    }
}
