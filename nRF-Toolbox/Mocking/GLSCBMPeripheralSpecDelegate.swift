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

class GLSCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    let log = NordicLog(category: "GlucoseMock")
    
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
            delegate: self
        )
        .build()
    
    enum MockError: Error {
        case notificationsNotEnabled, operationNotSupported, incorrectCommand
    }

    private var records: [[UInt8]] = [
        [0x07, 0x00, 0x00, 0xdc, 0x07, 0x01, 0x01, 0x0c, 0x1e, 0x05, 0x00, 0x00, 0x26, 0xd2, 0x11],
        [0x07, 0x01, 0x00, 0xdc, 0x07, 0x01, 0x01, 0x0c, 0x1e, 0x08, 0x00, 0x00, 0x3d, 0xd2, 0x11],
        [0x07, 0x02, 0x00, 0xdc, 0x07, 0x01, 0x01, 0x0c, 0x1e, 0x0b, 0x00, 0x00, 0x54, 0xd2, 0x11],
        [0x07, 0x03, 0x00, 0xdc, 0x07, 0x01, 0x01, 0x0c, 0x1e, 0x0e, 0x00, 0x00, 0x6b, 0xd2, 0x11],
        [0x07, 0x04, 0x00, 0xdc, 0x07, 0x01, 0x01, 0x0c, 0x1e, 0x11, 0x00, 0x00, 0x82, 0xd2, 0x11],
        [0x07, 0x05, 0x00, 0xdc, 0x07, 0x01, 0x01, 0x0c, 0x1e, 0x14, 0x00, 0x00, 0x99, 0xd2, 0x11],
    ]
    
    private var racpResponse = Data([0x06, 0x00, 0x01, 0x01])
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
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
                    sendResponse(index)
                }
                peripheral.simulateValueUpdate(racpResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            case .firstRecord:
                sendResponse(records.startIndex)
                peripheral.simulateValueUpdate(racpResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            case .lastRecord:
                sendResponse(records.endIndex - 1)
                peripheral.simulateValueUpdate(racpResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            default:
                return .failure(MockError.incorrectCommand)
            }
        default:
            return .failure(MockError.operationNotSupported)
        }
    }
    
    private var isMeasurementNotificationEnabled = false
    private var isRacpNotificationEnabled = false
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .glucoseMeasurement:
            isMeasurementNotificationEnabled = enabled
        case .recordAccessControlPoint:
            isRacpNotificationEnabled = enabled
        default:
            return .failure(MockError.operationNotSupported)
        }
        
        return .success(())
    }
    
    func sendResponse(_ index: Int) {
        let data = Data(records[index])
        peripheral.simulateValueUpdate(data, for: CBMCharacteristicMock.glucoseMeasurement)
    }
}

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
