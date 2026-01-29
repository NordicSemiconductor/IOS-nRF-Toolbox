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
        properties: .indicate,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let bpsFeature = CBMCharacteristicMock(
        type: .bloodPressureFeature,
        properties: [.read],
        descriptors: .clientCharacteristicConfiguration
    )
}

private extension CBMServiceMock {
    
    static let bloodPressure = CBMServiceMock(
        type: .bloodPressure,
        primary: true,
        characteristics: .bloodPresssureMeasurement, .bpsFeature,
    )
}

// MARK: BPS

class BPSCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    private let featureResponse = Data([0x00, 0x01])
    
    private let log = NordicLog(category: "BloodPressureMock")
    private var timerCancellable: AnyCancellable?
    
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
            delegate: self,
            connectionInterval: 0.02,
        )
        .build()
    
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .bloodPressure
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        switch characteristic.uuid {
        case CBMUUID.bloodPressureFeature:
            return .success(featureResponse)
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }

    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .bloodPresssureMeasurement:
            startEmulation(peripheral, characteristic)
            return .success(())
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        return .failure(MockError.writingIsNotSupported)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: (any Error)?) {
        log.debug("\(type(of: self)).\(#function)")
        timerCancellable?.cancel()
        timerCancellable = nil
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
        return Data(
            [
                0x1f,   // Flags: All fields present
                UInt8.random(in: 0...255),
                0x00,   // Systolic: 121
                UInt8.random(in: 0...255),
                0x00,   // Diastolic: 81
                UInt8.random(in: 0...255),
                0x00,   // Mean Arterial Pressure: 106
                0xE9,   // Year LSB (2025)
                0x07,   // Year MSB (2025)
                UInt8.random(in: 1...12),   // Month
                UInt8.random(in: 1...28),   // Day
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
}
