//
//  ScanResult.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 27/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries
import CoreBluetoothMock

// - MARK: ScanResult
    
extension ConnectedDevicesViewModel {
    
    struct ScanResult: Identifiable, Equatable {
        let name: String?
        let rssi: Int
        let id: UUID
        let services: Set<Service>
        
        init(name: String?, rssi: Int, id: UUID, services: [String]) {
            self.name = name
            self.rssi = rssi
            self.id = id
            self.services = Set(services.map {
                Service.extendedFind(by: $0) ?? Service(name: "unknown", identifier: "service-\($0)", uuidString: $0, source: "unknown")
            })
        }
        
        func extend(using scanResult: ScanResult) -> ScanResult {
            var extendedServices = services.map(\.uuidString)
            extendedServices.append(contentsOf: scanResult.services.map(\.uuidString))
            return ScanResult(name: scanResult.name ?? self.name, rssi: scanResult.rssi,
                              id: id, services: extendedServices)
        }
        
        static func ==(lhs: ScanResult, rhs: ScanResult) -> Bool {
            return lhs.id == rhs.id
        }
    }
}
