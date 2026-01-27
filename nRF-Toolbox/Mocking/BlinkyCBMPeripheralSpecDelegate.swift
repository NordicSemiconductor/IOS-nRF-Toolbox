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

// MARK: - CoreBluetoothMock

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

// MARK: - Blinky

internal class BlinkyCBMPeripheralSpecDelegate: MockSpecDelegate {
    private var ledEnabled: Bool = false
    private var buttonPressed: Bool = false
    
    private var timerCancellable: AnyCancellable?
    
    private let log = NordicLog(category: "BlinkyCBMPeripheralSpecDelegate", subsystem: "com.nordicsemi.nrf-toolbox")
    
    private var ledData: Data {
        return ledEnabled ? Data([0x01]) : Data([0x00])
    }
    private var buttonData: Data {
        return buttonPressed ? Data([0x01]) : Data([0x00])
    }
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
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
            delegate: BlinkyCBMPeripheralSpecDelegate(),
            connectionInterval: 0.02,
        )
        .build()

    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .blinkyService
    }
    
    func reset() {
        log.debug(#function)
        ledEnabled = false
        buttonPressed = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, Error> {
        log.debug(#function)
        switch characteristic.uuid {
        case .buttonCharacteristic:
            return .success(buttonData)
        case .ledCharacteristic:
            ledEnabled = .random()
            return .success(ledData)
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        log.debug(#function)
        switch characteristic.uuid {
        case .ledCharacteristic:
            ledEnabled = data[0] != 0x00
            return .success(())
        default:
            return .failure(MockError.writingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .buttonCharacteristic:
            startEmulation(peripheral, characteristic: characteristic, enabled: enabled)
            return .success(())
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: (any Error)?) {
        log.debug(#function)
        reset()
    }
    
    private func startEmulation(_ peripheral: CBMPeripheralSpec, characteristic: CBMCharacteristicMock, enabled: Bool) {
        if timerCancellable == nil {
            timerCancellable = Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    buttonPressed = .random()
                    peripheral.simulateValueUpdate(buttonData, for: characteristic)
                }
        }
    }
}
