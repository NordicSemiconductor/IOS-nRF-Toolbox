//
//  HeartRateCBMPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 14/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

class HeartRateCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    let log = NordicLog(category: "HeartRateMock")
    lazy var cancellables = Set<AnyCancellable>()
    
    private let sensorLocation = HeartRateMeasurement.SensorLocation.wrist
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Heart rate",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.heartRate]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Heart Rate Sensor",
            services: [.heartRate],
            delegate: self
        )
        .build()
    
    enum MockError: Error {
        case notifyIsNotSupported, readingIsNotSupported, writingIsNotSupported, incorrectCommand
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        switch characteristic.uuid {
        case CBMUUID.bodySensorLocation:
            let data = withUnsafeBytes(of: sensorLocation.rawValue) { Data($0) }
            return .success(data)
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        switch characteristic.uuid {
        case CBMUUID.heartRateControlPoint:
            let resetCaloriesBytes: [UInt8] = [0x01]  // Reset calories counter
            let resetCaloriesCommand = Data(resetCaloriesBytes)
            if (resetCaloriesCommand == data) {
                caloriesUsage = 0
                return .success(())
            } else {
                return .failure(MockError.incorrectCommand)
            }
        default:
            return .failure(MockError.writingIsNotSupported)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .heartRateMeasurement:
            heartRateMeasurementChanged(peripheral, characteristic: characteristic, enabled: enabled)
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
    
    func heartRateMeasurementChanged(_ peripheral: CBMPeripheralSpec, characteristic: CBMCharacteristicMock, enabled: Bool) {
        guard enabled else {
            cancellables.removeAll()
            return
        }
        
        Timer.publish(every: 2.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let flags = generateNextFlags()
                let heartRate = generateNextHeartRate()
                let caloriesUsage = generateNextCaloriesUsage()
                let rrIntervals = generateRRIntervals()
                let data = flags + heartRate + caloriesUsage + rrIntervals
                self.log.debug("Sending \(data.hexEncodedString()).")
                peripheral.simulateValueUpdate(data, for: characteristic)
            }
            .store(in: &cancellables)
    }
    
    var isBodyContactPresent = false
    var latestHeartRate: UInt8 = 0
    var caloriesUsage: UInt16 = 0
    var rrInterval: UInt16 = 0
    
    func generateNextFlags() -> Data {
        isBodyContactPresent = !isBodyContactPresent
        if (isBodyContactPresent) {
            return Data([0x1E])
        } else {
            return Data([0x1C])
        }
    }
    
    func generateNextHeartRate() -> Data {
        if latestHeartRate == UInt8.max {
            latestHeartRate = 0
        } else {
            latestHeartRate += 1
        }
        let byteArray: [UInt8] = [latestHeartRate]
        return Data(byteArray)
    }
    
    func generateNextCaloriesUsage() -> Data {
        if caloriesUsage+3 >= UInt16.max {
            caloriesUsage = 0
        } else {
            caloriesUsage += 3 // average per minute
        }
        return withUnsafeBytes(of: caloriesUsage.littleEndian) { Data($0) }
    }
    
    func generateNextRRInterval() -> UInt16 {
        if rrInterval == UInt16.max {
            rrInterval = 0
        } else {
            rrInterval += 1
        }
        return rrInterval
    }
    
    func generateRRIntervals() -> Data {
        let one = withUnsafeBytes(of: generateNextRRInterval().littleEndian) { Data($0) }
        let two = withUnsafeBytes(of: generateNextRRInterval().littleEndian) { Data($0) }
        let three = withUnsafeBytes(of: generateNextRRInterval().littleEndian) { Data($0) }
        return one + two + three
    }
}

// MARK: - CoreBluetoothMock

private extension CBMUUID {
    static let heartRateMeasurement = CBMUUID(characteristic: .heartRateMeasurement)
    
    static let heartRateControlPoint = CBMUUID(characteristic: .heartRateControlPoint)
    static let bodySensorLocation = CBMUUID(characteristic: .bodySensorLocation)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let heartRateMeasurement = CBMCharacteristicMock(
        type: .heartRateMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let bodySensorLocation = CBMCharacteristicMock(
        type: .bodySensorLocation,
        properties: .read
    )
    
    static let heartRateControlPoint = CBMCharacteristicMock(
        type: .heartRateControlPoint,
        properties: .write
    )
}

private extension CBMServiceMock {
    
    static let heartRate = CBMServiceMock(
        type: .heartRate,
        primary: true,
        characteristics: .heartRateMeasurement, .bodySensorLocation, .heartRateControlPoint,
    )
}
