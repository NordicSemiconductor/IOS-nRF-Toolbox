//
//  BPSCBMPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 15/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

class BPSCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    let log = NordicLog(category: "BloodPressureMock")
    lazy var cancellables = Set<AnyCancellable>()
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Blood pressure",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.bloodPressure]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Blood Pressure Sensor",
            services: [.bloodPressure],
            delegate: self
        )
        .build()
    
    enum MockError: Error {
        case notificationsNotEnabled, operationNotSupported, incorrectCommand, readingIsNotSupported
    }
    
    func generateData() -> Data {
        return Data(
            [
                0x1f,   // Flags: All fields present
                UInt8.random(in: 0...255),
                0x00,   // Systolic: 121
                UInt8.random(in: 0...255),
                0x00,   // Diastolic: 81
                UInt8.random(in: 0...255),
                0x00,   // Mean Arterial Pressure: 106
                0xE4,   // Year LSB (2020)
                0x07,   // Year MSB (2020)
                UInt8.random(in: 1...12),   // Month: May
                UInt8.random(in: 1...28),   // Day: 21
                0x0A,   // Hour: 10
                0x1E,   // Minute: 30
                0x2D,   // Second: 45
                UInt8.random(in: 0...255),
                0x00,   // Pulse Rate: 72.0 bpm
                0x01,   // User ID: 1
                0x06,
                0x00    // Measurement Status: Irregular pulse detected and loose cuff
            ]
        )
    }
    
    let featureResponse = Data([0x00, 0x00])
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        switch characteristic.uuid {
        case CBMUUID.bloodPressureFeature:
            return .success(featureResponse)
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }

    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .bloodPresssureMeasurement:
            Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [unowned self] _ in
                    peripheral.simulateValueUpdate(self.generateData(), for: characteristic)
                }
                .store(in: &cancellables)
        default:
            return .failure(MockError.operationNotSupported)
        }
        
        return .success(())
    }
}

// MARK: - CoreBluetoothMock

private extension CBMUUID {
    static let bloodPresssureMeasurement = CBMUUID(characteristic: .bloodPressureMeasurement)
    
    static let bloodPressureFeature = CBMUUID(characteristic: .bloodPressureFeature)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let bloodPresssureMeasurement = CBMCharacteristicMock(
        type: .bloodPresssureMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let recordAccessControlPoint = CBMCharacteristicMock(
        type: .bloodPressureFeature,
        properties: [.write, .indicate],
    )
}

private extension CBMServiceMock {
    
    static let bloodPressure = CBMServiceMock(
        type: .bloodPressure,
        primary: true,
        characteristics: .bloodPresssureMeasurement, .recordAccessControlPoint,
    )
}
