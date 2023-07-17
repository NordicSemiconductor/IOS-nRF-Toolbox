//
//  CBMPeripheralPreview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 17/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library
import CoreBluetoothMock

// MARK: - Constants

extension CBMUUID {
    static let nordicBlinkyService  = CBMUUID(string: "00001523-1212-EFDE-1523-785FEABCD123")
    static let buttonCharacteristic = CBMUUID(string: "00001524-1212-EFDE-1523-785FEABCD123")
    static let ledCharacteristic    = CBMUUID(string: "00001525-1212-EFDE-1523-785FEABCD123")
    
    static let heartRate            = CBMUUID(string: "180D")
    static let runningSpeedCadence  = CBMUUID(string: "1814")
    static let weightScale          = CBMUUID(string: "181D")
    static let cyclingSpeedCadence  = CBMUUID(string: "1816")
}

// MARK: - Services

extension CBMCharacteristicMock {
    
    static let buttonCharacteristic = CBMCharacteristicMock(
        type: .buttonCharacteristic,
        properties: [.notify, .read],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )

    static let ledCharacteristic = CBMCharacteristicMock(
        type: .ledCharacteristic,
        properties: [.write, .read]
    )
    
}

extension CBMServiceMock {

    static let blinkyService = CBMServiceMock(
        type: .nordicBlinkyService,
        primary: true,
        characteristics:
            .buttonCharacteristic,
            .ledCharacteristic
    )
    
    static let heartRate = CBMServiceMock(
        type: .heartRate,
        primary: true
    )
    
    static let runningSpeedCadence = CBMServiceMock(
        type: .runningSpeedCadence,
        primary: true
    )
    
    static let weightScale = CBMServiceMock(
        type: .weightScale,
        primary: true
    )
}

// MARK: - Blinky Implementation
struct MockError: Swift.Error {
    let title: String
    let message: String
}

/// The delegate implements the behavior of the mocked device.
private class BlinkyCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    // MARK: States
    
    /// State of the LED.
    private var ledEnabled: Bool = false
    /// State of the Button.
    private var buttonPressed: Bool = false
    
    // MARK: Encoders
    
    /// LED state encoded as Data.
    ///
    /// - 0x01 - LED is ON.
    /// - 0x00 - LED is OFF.
    private var ledData: Data {
        return ledEnabled ? Data([0x01]) : Data([0x00])
    }
    
    /// Button state encoded as Data.
    ///
    /// - 0x01 - Button is pressed.
    /// - 0x00 - Button is released.
    private var buttonData: Data {
        return buttonPressed ? Data([0x01]) : Data([0x00])
    }
    
    // MARK: Event handlers
    
    func reset() {
        ledEnabled = false
        buttonPressed = false
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        if characteristic.uuid == .ledCharacteristic {
            return .success(ledData)
        } else {
            return .success(buttonData)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        if data.count > 0 {
            ledEnabled = data[0] != 0x00
        }
        return .success(())
    }
}

private class WeightCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    func peripheralDidReceiveConnectionRequest(_ peripheral: CBMPeripheralSpec) -> Result<Void, Swift.Error> {
        .failure(MockError(title: "Connection Error", message: "Failed to connect the peripheral"))
    }
}

// MARK: - Blinky Definition

/// This device will advertise with 2 different types of packets, as nRF Blinky and an iBeacon (with a name).
/// As iOS prunes the iBeacon manufacturer data, only the name is available.
let blinky = CBMPeripheralSpec
    .simulatePeripheral(proximity: .immediate)
    .advertising(
        advertisementData: [
            CBAdvertisementDataIsConnectable : false as NSNumber,
            CBAdvertisementDataLocalNameKey : "Blinky",
            CBAdvertisementDataServiceUUIDsKey : [CBMUUID.nordicBlinkyService]
        ],
        withInterval: 2.0,
        delay: 5.0,
        alsoWhenConnected: false
    )
    .connectable(
        name: "nRF Blinky",
        services: [.blinkyService],
        delegate: BlinkyCBMPeripheralSpecDelegate()
    )
    .build()

let hrm = CBMPeripheralSpec
    .simulatePeripheral(proximity: .near)
    .advertising(
        advertisementData: [
            CBAdvertisementDataIsConnectable : true as NSNumber,
            CBAdvertisementDataLocalNameKey : "Heart Rate Monitor",
            CBAdvertisementDataServiceUUIDsKey : [CBMUUID.heartRate]
        ],
        withInterval: 2.0,
        delay: 5.0,
        alsoWhenConnected: false
    )
    .connectable(
        name: "Heart Rate Monitor",
        services: [.heartRate],
        delegate: BlinkyCBMPeripheralSpecDelegate() // TODO: Change
    )
    .build()

let runningSpeedCadenceSensor = CBMPeripheralSpec
    .simulatePeripheral(proximity: .far)
    .advertising(
        advertisementData: [
            CBAdvertisementDataIsConnectable : true as NSNumber,
            CBAdvertisementDataLocalNameKey : "Running Speed and Cadence sensor",
            CBAdvertisementDataServiceUUIDsKey : [CBMUUID.runningSpeedCadence, CBMUUID.heartRate, CBMUUID.cyclingSpeedCadence]
        ],
        withInterval: 2.0,
        delay: 5.0,
        alsoWhenConnected: false
    )
    .connectable(
        name: "Running Sensor",
        services: [.runningSpeedCadence],
        delegate: BlinkyCBMPeripheralSpecDelegate() // TODO: Change
    )
    .build()

let weightScale = CBMPeripheralSpec
    .simulatePeripheral(proximity: .immediate)
    .advertising(
        advertisementData: [
            CBAdvertisementDataIsConnectable : true as NSNumber,
            CBAdvertisementDataLocalNameKey : "Weight Scale",
            CBAdvertisementDataServiceUUIDsKey : [CBMUUID.weightScale]
        ],
        withInterval: 2.0,
        delay: 5.0,
        alsoWhenConnected: false
    )
    .connectable(
        name: "Weight Scale",
        services: [.weightScale],
        delegate: WeightCBMPeripheralSpecDelegate() // TODO: Change
    )
    .build()
