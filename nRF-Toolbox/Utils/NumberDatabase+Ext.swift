//
//  NumberDatabase+Ext.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 11/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Bluetooth_Numbers_Database
import SwiftUI

extension Service: Hashable {
    
    private static let serviceIcons: [Service : String] = [
        .runningSpeedAndCadence : "figure.run",
        .cyclingSpeedAndCadence : "figure.outdoor.cycle",
        .heartRate : "heart",
//        .bloodPressure,
//        .glucose,
//        .continuousGlucoseMonitoring,
        .healthThermometer : "medical.thermometer"
    ]
    
    private static let colors: [Service : Color] = [
        .runningSpeedAndCadence : .cyan,
        .cyclingSpeedAndCadence : .green,
        .heartRate : .red,
        .bloodPressure : .purple,
        .glucose : .orange,
        .continuousGlucoseMonitoring : .yellow,
        .healthThermometer : .indigo
    ]
    
    static var supportedServices: [Service] = [
        .runningSpeedAndCadence,
        .cyclingSpeedAndCadence,
        .heartRate,
        .bloodPressure,
        .glucose,
        .continuousGlucoseMonitoring,
        .healthThermometer
    ]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.uuidString)
    }
    
    var systemImage: Image? { Service.serviceIcons[self].flatMap { Image(systemName: $0) } }
    var color: Color? { Service.colors[self] }
    var isSupported: Bool { Service.supportedServices.contains(self) }
}

extension Service: Identifiable {
    public var id: String {
        uuidString
    }
}
