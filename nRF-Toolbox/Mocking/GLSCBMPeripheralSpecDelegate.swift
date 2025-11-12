//
//  GLSCBMPeripheralSpecDelegate.swift
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
    static let glucoseMeasurement = CBMUUID(characteristic: .glucoseMeasurement)
    
    static let recordAccessControlPoint = CBMUUID(characteristic: .recordAccessControlPoint)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let glucoseMeasurement = CBMCharacteristicMock(
        type: .glucoseMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let recordAccessControlPoint = CBMCharacteristicMock(
        type: .recordAccessControlPoint,
        properties: [.write, .indicate],
        descriptors: .clientCharacteristicConfiguration
    )
}

private extension CBMServiceMock {
    
    static let glucose = CBMServiceMock(
        type: .glucoseService,
        primary: true,
        characteristics: .glucoseMeasurement, .recordAccessControlPoint,
    )
}

// MARK: GLS

class GLSCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    private var sequenceNumber: UInt8 = 0
    
    private func createRecord() -> [UInt8] {
        defer {
            sequenceNumber += 1
        }
        return [
            0x1F,  // Flags: All optional fields present
            sequenceNumber,
            0x00,  // Sequence Number
            0xE9,
            0x07,  // Year: 2025 (little-endian)
            0x05,  // Month: May
            0x15,  // Day: 21
            0x0A,  // Hour: 10
            0x1E,  // Minute: 30
            sequenceNumber,  // Second: 45
            0x00,
            0x00,  // Time Offset: 0 minutes
            sequenceNumber,
            0x00,  // Glucose concentration (IEEE 11073 format) and type/sample location
            0x41,  // 4 - location, 1 - type
            0x01,
            0x00,  // Status - device battery low
        ]
    }
    
    private func createRecords(_ number: Int) -> [[UInt8]] {
        var result:[[UInt8]] = []
        
        for _ in 0..<number {
            result.append(createRecord())
        }
        
        return result
    }
    
    private lazy var records = createRecords(60)
    
    private var racpResponse = Data([0x06, 0x00, 0x01, 0x01])
    
    private var isMeasurementNotificationEnabled = false
    private var isRacpNotificationEnabled = false
    
    private let log = NordicLog(category: "GlucoseMock")
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Glucose measurement",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.glucoseService]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Glucose Measurement Sensor",
            services: [.glucose],
            delegate: self,
            connectionInterval: 0.02,
        )
        .build()
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .glucose
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        switch characteristic.uuid {
        case CBMUUID.recordAccessControlPoint:
            let command = data.littleEndianBytes(atOffset: 0, as: UInt8.self)
            let op = data.littleEndianBytes(atOffset: 1, as: UInt8.self)
            let opCode = RecordOperator(rawValue: UInt8(op))
        
            if command != 0x01 {
                return .failure(MockError.incorrectCommand)
            }
            
            guard isRacpNotificationEnabled, isMeasurementNotificationEnabled else {
                return .failure(MockError.notificationsNotEnabled)
            }
            
            switch opCode {
            case .allRecords:
                for (index, _) in records.enumerated() {
                    sendResponse(peripheral, index)
                }
                peripheral.simulateValueUpdate(racpResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            case .firstRecord:
                sendResponse(peripheral, records.startIndex)
                peripheral.simulateValueUpdate(racpResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            case .lastRecord:
                sendResponse(peripheral, records.endIndex - 1)
                peripheral.simulateValueUpdate(racpResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            default:
                return .failure(MockError.incorrectCommand)
            }
        default:
            return .failure(MockError.writingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .glucoseMeasurement:
            isMeasurementNotificationEnabled = enabled
        case .recordAccessControlPoint:
            isRacpNotificationEnabled = enabled
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, any Error> {
        return .failure(MockError.readingIsNotSupported)
    }
    
    private func sendResponse(_ peripheral: CBMPeripheralSpec, _ index: Int) {
        let data = Data(records[index])
        peripheral.simulateValueUpdate(data, for: CBMCharacteristicMock.glucoseMeasurement)
    }
}
