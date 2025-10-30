//
//  CSCSCBMPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 23/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

// MARK: - CoreBluetoothMock

private extension CBMUUID {
    static let cscMeasurement = CBMUUID(characteristic: .cscMeasurement)
    
    static let cscFeature = CBMUUID(characteristic: .cscFeature)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let cscMeasurement = CBMCharacteristicMock(
        type: .cscMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let cscFeature = CBMCharacteristicMock(
        type: .cscFeature,
        properties: .read
    )
}

private extension CBMServiceMock {
    
    static let cyclingSpeedCadence = CBMServiceMock(
        type: .cyclingSpeedCadence,
        primary: true,
        characteristics: .cscMeasurement, .cscFeature
    )
}

// MARK: CSCS

class CSCSCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    private var moment: UInt16 = 0
    private var wheelData: UInt32 = 0
    private var crankData: UInt16 = 0
    
    private var notifySCControlPoint: Bool = false
    
    private let log = NordicLog(category: "CyclingSpeedAndCadence")
    private var timerCancellable: AnyCancellable?
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .cyclingSpeedCadence
    }

    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Cycling Speed and Cadence sensor",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.cyclingSpeedCadence]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Cycling Sensor",
            services: [.cyclingSpeedCadence],
            delegate: self,
            connectionInterval: 0.02,
        )
        .build()
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        log.debug(#function)
        switch characteristic.uuid {
        case .cscFeature:
            return .success(Data([0x03]))
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        log.debug(#function)
        return .failure(MockError.writingIsNotSupported)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .cscMeasurement:
            startEmulation(peripheral, characteristic)
            return .success(())
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: (any Error)?) {
        log.debug(#function)
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func generateNextValue<T: FixedWidthInteger>(_ value: T) -> T {
        return if value == T.max {
            0
        } else {
            value + 1
        }
    }
    
    private func startEmulation(_ peripheral: CBMPeripheralSpec, _ characteristic: CBMCharacteristicMock) {
        if timerCancellable == nil {
            timerCancellable = Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [unowned self] _ in
                    peripheral.simulateValueUpdate(self.generateData(), for: characteristic)
                }
        }
    }
    
    private func generateData() -> Data {
        moment = generateNextValue(moment)
        wheelData = generateNextValue(wheelData)
        crankData = generateNextValue(crankData)
        let momentInSeconds = (moment % 63) * 1024
        
        return Data(
            [
                0x03,                                   // Wheel & crank data is present
                UInt8(wheelData & 0xFF),
                UInt8((wheelData >> 8) & 0xFF),
                UInt8((wheelData >> 16) & 0xFF),
                UInt8((wheelData >> 24) & 0xFF),        // wheel rotations
                UInt8(momentInSeconds & 0xFF),
                UInt8((momentInSeconds >> 8) & 0xFF),   // 1024 -> 1 second
                UInt8(crankData & 0xFF),
                UInt8((crankData >> 8) & 0xFF),         // crank rotations
                UInt8(momentInSeconds & 0xFF),
                UInt8((momentInSeconds >> 8) & 0xFF),   // 1024 -> 1 second
            ]
        )
    }
}
