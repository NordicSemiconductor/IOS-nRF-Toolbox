//
//  RSCSCBMPeripheralSpecDelegate.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 21/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

// MARK: - RSCSCBMPeripheralSpecDelegate

public class RSCSCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    var enabledFeatures: BitField<RSCSFeature> = .all()
    var sensorLocation: RunningSpeedAndCadence.SensorLocation = .inShoe
    
    var notifySCControlPoint: Bool = false
    var measurementTimer: Timer?

    weak var delegate: RSCSDelegate?
    
    enum MockError: Error {
        case notifyIsNotSupported, readingIsNotSupported, writingIsNotSupported
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        switch characteristic.uuid {
        case CBMUUID.rscFeature:
            let allFeatures = BitField<RSCSFeature>.all()
                .data(clippedTo: UInt8.self)
            var allFeaturesData = Data([0xff])
            allFeaturesData.append(allFeatures)
            return .success(allFeaturesData) // Support all features
        case CBMUUID.sensorLocation:
            return .success(Data([sensorLocation.rawValue]))
        default:
            return .failure(MockError.readingIsNotSupported)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        switch characteristic.uuid {
        case CBMUUID.scControlPoint:
            let opCode = RunningSpeedAndCadence.OpCode(rawValue: UInt8(data.littleEndianBytes(as: UInt8.self)))!
            switch opCode {
            case .setCumulativeValue:
                let value: UInt32 = UInt32(data.littleEndianBytes(as: UInt32.self))
                delegate?.didReceiveSetCumulativeValue(value: value)
            case .startSensorCalibration:
                delegate?.didReceiveStartSensorCalibration()
            case .updateSensorLocation:
                let location = RunningSpeedAndCadence.SensorLocation(rawValue: UInt8(data.littleEndianBytes(as: UInt32.self)))!
                delegate?.didReceiveUpdateSensorLocation(location)
            case .requestSupportedSensorLocations:
                delegate?.didReceiveRequestSupportedSensorLocations()
            default:
                return .failure(MockError.writingIsNotSupported)
            }
        default:
            return .failure(MockError.writingIsNotSupported)
        }
        return .success(())
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .rscMeasurement:
            delegate?.measurementNotificationStatusChanged(peripheral, characteristic: characteristic, enabled: enabled)
        case .scControlPoint:
            delegate?.controlPointNotificationStatusChanged(enabled)
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
}

// MARK: - CoreBluetoothMock

typealias SensorLocation = RunningSpeedAndCadence.SensorLocation
typealias SupportedSensorLocationsResponse = RunningSpeedAndCadence.SupportedSensorLocations

internal extension CBMUUID {
    static let rscMeasurement = CBMUUID(characteristic: .rscMeasurement)
    
    static let rscFeature = CBMUUID(characteristic: .rscFeature)
    static let sensorLocation = CBMUUID(characteristic: .sensorLocation)
    
    static let scControlPoint = CBMUUID(characteristic: .scControlPoint)
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

internal extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

internal extension CBMCharacteristicMock {
    static let rscMeasurement = CBMCharacteristicMock(
        type: .rscMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
    
    static let rscFeature = CBMCharacteristicMock(
        type: .rscFeature,
        properties: .read
    )
    
    static let sensorLocation = CBMCharacteristicMock(
        type: .sensorLocation,
        properties: .read
    )
    
    static let scControlPoint = CBMCharacteristicMock(
        type: .scControlPoint,
        properties: [.write, .indicate],
        descriptors: .clientCharacteristicConfiguration
    )
}

internal extension CBMServiceMock {
    
    static let runningSpeedCadence = CBMServiceMock(
        type: .runningSpeedCadence,
        primary: true,
        characteristics: .rscMeasurement, .rscFeature, .sensorLocation, .scControlPoint
    )
}
