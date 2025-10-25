//
//  BlinkyCBMPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 17/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_Common_Libraries
import iOS_BLE_Library_Mock
import CoreBluetoothMock

// MARK: - Blinky

/**
 This device will advertise with 2 different types of packets, as nRF Blinky and an iBeacon (with a name).
 As iOS prunes the iBeacon manufacturer data, only the name is available.
 */
let blinky = CBMPeripheralSpec
    .simulatePeripheral(proximity: .immediate)
    .advertising(
        advertisementData: [
            CBAdvertisementDataIsConnectable : true as NSNumber,
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
        characteristics: .buttonCharacteristic, .ledCharacteristic
    )
}

// MARK: - BlinkyCBMPeripheralSpecDelegate

internal class BlinkyCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .blinkyService
    }
    
    enum MockError: Error {
        case notifyIsNotSupported, readingIsNotSupported, writingIsNotSupported
    }
    
    // MARK: States
    
    /// State of the LED.
    private var ledEnabled: Bool = false
    /// State of the Button.
    private var buttonPressed: Bool = false
    
    private lazy var cancellables = Set<AnyCancellable>()
    
    private let log = NordicLog(category: "BlinkyCBMPeripheralSpecDelegate",
                                subsystem: "com.nordicsemi.nrf-toolbox")
    
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
        log.debug(#function)
        ledEnabled = false
        buttonPressed = false
        cancellables.removeAll()
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        log.debug(#function)
        if characteristic.uuid == .ledCharacteristic {
            ledEnabled = .random()
            log.debug("Randomised LED to \(ledEnabled)")
            return .success(ledData)
        } else {
            return .success(buttonData)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        log.debug(#function)
        if data.count > 0 {
            ledEnabled = data[0] != 0x00
        }
        return .success(())
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .buttonCharacteristic:
            Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    buttonPressed = .random()
                    log.debug("Button Pressed \(buttonPressed)")
                    peripheral.simulateValueUpdate(buttonData, for: characteristic)
                }
                .store(in: &cancellables)
            return .success(())
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: (any Error)?) {
        log.debug(#function)
        cancellables.removeAll()
    }
}
