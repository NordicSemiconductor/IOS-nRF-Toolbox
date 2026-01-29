//
//  CGMSCBMPeripheralSpecDelegate.swift
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
    static let cgmsMeasurement = CBMUUID(characteristic: .cgmMeasurement)
    static let cgmSpecificOpsControlPoint = CBMUUID(characteristic: .cgmSpecificOpsControlPoint)
    static let cgmSessionStartTime = CBMUUID(characteristic: .cgmSessionStartTime)
    static let cgmFeature = CBMUUID(characteristic: .cgmFeature)
    
    static let recordAccessControlPoint = CBMUUID(characteristic: .recordAccessControlPoint)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let cgmsMeasurement = CBMCharacteristicMock(
        type: .cgmsMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let cgmsFeature = CBMCharacteristicMock(
        type: .cgmFeature,
        properties: .read,
    )
    
    static let sessionStartTime = CBMCharacteristicMock(
        type: .cgmSessionStartTime,
        properties: [.write, .writeWithoutResponse, .read],
    )
    
    static let sopCp = CBMCharacteristicMock(
        type: .cgmSpecificOpsControlPoint,
        properties: [.write, .indicate],
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let recordAccessControlPoint = CBMCharacteristicMock(
        type: .recordAccessControlPoint,
        properties: [.write, .indicate],
        descriptors: .clientCharacteristicConfiguration
    )
}

private extension CBMServiceMock {
    
    static let cgms = CBMServiceMock(
        type: .continuousGlucoseMonitoringService,
        primary: true,
        characteristics: .cgmsMeasurement, .cgmsFeature, .sopCp, .sessionStartTime, .recordAccessControlPoint,
    )
}

// MARK: CMGS

class CGMSCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    private var records: [[UInt8]] = []
    private var nextRecordIndex: UInt8 = 0
    private var numberOfRecordsResponse = Data([0x06, 0x00, 0x01, 0x06])
    private var reportRecordsResponse = Data([0x05, 0x00, 0x00, 0x00])
    
    private var isMeasurementNotificationEnabled = false
    private var isRacpNotificationEnabled = false
    private var isSocpNotificationEnabled = false
    
    private let log = NordicLog(category: "CGMSMock")
    private var timerCancellable: AnyCancellable?
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Continous glucose measurement",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.continuousGlucoseMonitoringService]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Continous Glucose Measurement",
            services: [.cgms],
            delegate: self,
            connectionInterval: 0.02,
        )
        .build()
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .cgms
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        log.debug("\(type(of: self)).\(#function)")
        switch characteristic.uuid {
        case CBMUUID.cgmFeature:
            return .success(Data([0x0F, 0x00, 0x00, 0x00]))
        case CBMUUID.cgmSessionStartTime:
            return .success(Data([0xE9, 0x07, 0x0A, 0x10, 0x0E, 0x10, 0x13, 0x00, 0x00]))
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        switch characteristic.uuid {
        case CBMUUID.cgmSessionStartTime:
            return .success(())
        case CBMUUID.cgmSpecificOpsControlPoint:
            return .success(())
        case CBMUUID.recordAccessControlPoint:
            let command = data.littleEndianBytes(atOffset: 0, as: UInt8.self)
            let op = data.littleEndianBytes(atOffset: 1, as: UInt8.self)
            let opCode = RecordOperator(rawValue: UInt8(op))
            
            guard isRacpNotificationEnabled, isMeasurementNotificationEnabled else {
                return .failure(MockError.notificationsNotEnabled)
            }

            if command == 0x04 {
                peripheral.simulateValueUpdate(numberOfRecordsResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                return .success(())
            } else if command == 0x01 {
                switch opCode {
                case .allRecords:
                    for (index, _) in records.enumerated() {
                        sendResponse(peripheral, index)
                    }
                    peripheral.simulateValueUpdate(reportRecordsResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                    return .success(())
                case .firstRecord:
                    sendResponse(peripheral, records.startIndex)
                    peripheral.simulateValueUpdate(reportRecordsResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                    return .success(())
                case .lastRecord:
                    sendResponse(peripheral, records.endIndex - 1)
                    peripheral.simulateValueUpdate(reportRecordsResponse, for: CBMCharacteristicMock.recordAccessControlPoint)
                    return .success(())
                default:
                    return .failure(MockError.incorrectCommand)
                }
            }
            return .failure(MockError.incorrectCommand)
        default:
            return .failure(MockError.writingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .cgmsMeasurement:
            isMeasurementNotificationEnabled = enabled
            startEmulation(peripheral, characteristic)
        case .recordAccessControlPoint:
            isRacpNotificationEnabled = enabled
        case .cgmSpecificOpsControlPoint:
            isSocpNotificationEnabled = enabled
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
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
                    guard let record = generateNewRecord() else {
                        timerCancellable?.cancel()
                        return
                    }
                    self.records.append(record)
                    sendResponse(peripheral, records.endIndex - 1)
                }
        }
    }
    
    private func sendResponse(_ peripheral: CBMPeripheralSpec, _ index: Int) {
        let data = Data(records[index])
        peripheral.simulateValueUpdate(data, for: CBMCharacteristicMock.cgmsMeasurement)
    }
    
    private func getRecordIndex() -> UInt8? {
        if nextRecordIndex == UInt8.max {
            return nil
        } else {
            nextRecordIndex += 1
        }
        return nextRecordIndex
    }
    
    private func generateNewRecord() -> [UInt8]? {
        guard let index = getRecordIndex() else { return nil }
        return [
            0x0F,  // Size: 15 bytes (6 base + 2 trend + 2 quality + 1 warning + 1 temp + 1 status + 2 CRC + size)
            0xE3,  // Flags: All optional fields present (binary 11100011)
            0x79 + nextRecordIndex % 10,
            0x00,  // Glucose concentration: 121 mg/dL
            index,
            0x00,  // Time offset:
            0x01,  // Sensor status
            0x02,  // Calibration temp status
            0x03,  // Warning status
            0x50,
            0x00,  // Trend: 80 mg/dL/min
            0x60,
            0x00,  // Quality: 96 mg/dL
            0xEC,
            0xAC   // CRC: Placeholder (valid CRC for this data)
        ]
    }
}
