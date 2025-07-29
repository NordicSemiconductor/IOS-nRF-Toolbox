//
//  RunningSpeedAndCadence.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 29/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_Common_Libraries
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database

// MARK: RSCS

class RunningSpeedAndCadence {
    public var enabledFeatures: BitField<RSCSFeature> = .all()
    public var sensorLocation: RSCSSensorLocation = .inShoe
    
    var notifySCControlPoint: Bool = false
    
    let log = NordicLog(category: "RunningSpeedAndCadence")
    lazy var cancellables = Set<AnyCancellable>()
    
    public init(enabledFeatures: BitField<RSCSFeature>, sensorLocation: RSCSSensorLocation) {
        self.enabledFeatures = enabledFeatures
        self.sensorLocation = sensorLocation
    }
    
    public init() {
        self.enabledFeatures = .all()
        self.sensorLocation = .inShoe
        self.peripheralDelegate.delegate = self
    }

    private var peripheralDelegate = RSCSCBMPeripheralSpecDelegate()
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Running Speed and Cadence sensor",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.runningSpeedCadence]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Running Sensor",
            services: [.runningSpeedCadence],
            delegate: self.peripheralDelegate
        )
        .build()
    
    var measurement: RSCSMeasurement = RSCSMeasurement(
        flags: .all(),
        instantaneousSpeed: 2.5,
        instantaneousCadence: 170,
        instantaneousStrideLength: 80,
        totalDistance: 0
    )
    
    var notifyMeasurement: Bool = false
    
    // MARK: Public methods
    
    public func postMeasurement(_ measurement: RSCSMeasurement) {
        
    }

    public func randomizeMeasurement(flags: BitField<RSCSFeature> = []) {
        self.measurement.flags = flags
        let newIS = Double.random(in: 0...3)
        self.measurement.instantaneousSpeed = Measurement<UnitSpeed>(value: newIS, unit: .metersPerSecond)
        self.measurement.instantaneousCadence = Int.random(in: 166 ... 174)
        
        if flags.contains(.instantaneousStrideLengthMeasurement) {
            self.measurement.instantaneousStrideLength = Int.random(in: 75 ... 85)
        }
        
        if flags.contains(.totalDistanceMeasurement), let distanceValue = measurement.totalDistance?.value {
            self.measurement.totalDistance =
                Measurement<UnitLength>(value: distanceValue + Double.random(in: 1...2), unit: .meters)
        }
    }
}
