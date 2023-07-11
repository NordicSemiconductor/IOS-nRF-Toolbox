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
        case .HeartRate.heartRate:
            icon = Image(systemName: "heart.fill")
            name = Service.HeartRate.heartRate.name
            color = .red
        case .RunningSpeedAndCadence.runningSpeedAndCadence:
            icon = Image(systemName: "figure.run")
            name = Service.RunningSpeedAndCadence.runningSpeedAndCadence.name
            color = .yellow
        case .WeightScale.weightScale:
            icon = Image(systemName: "scalemass.fill")
            name = Service.WeightScale.weightScale.name
            color = .green
        default:
            return nil
        }
    }
}
