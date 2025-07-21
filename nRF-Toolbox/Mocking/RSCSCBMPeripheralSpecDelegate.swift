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

// MARK: - RSCSCBMPeripheralSpecDelegate

public class RSCSCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    var enabledFeatures: RunningSpeedAndCadence.RSCFeature = .all
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
        if characteristic.uuid == CBMUUID.rscFeature {
            return .success(Data([0xff, enabledFeatures.rawValue])) // Support all features
        } else if characteristic.uuid == CBMUUID.sensorLocation {
            return .success(Data([sensorLocation.rawValue]))
        } else {
            return .failure(MockError.readingIsNotSupported)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        if characteristic.uuid == CBMUUID.scControlPoint {
            let opCode = RunningSpeedAndCadence.OpCode(rawValue: data.read(offset: 0))!
            switch opCode {
            case .setCumulativeValue:
                let value: UInt32 = data.read(offset: 1)
                delegate?.didReceiveSetCumulativeValue(value: value)
            case .startSensorCalibration:
                delegate?.didReceiveStartSensorCalibration()
            case .updateSensorLocation:
                let location = RunningSpeedAndCadence.SensorLocation(rawValue: data.read(offset: 1))!
                delegate?.didReceiveUpdateSensorLocation(location)
            case .requestSupportedSensorLocations:
                delegate?.didReceiveRequestSupportedSensorLocations()
            default:
                return .failure(MockError.writingIsNotSupported)
            }
        } else {
            return .failure(MockError.writingIsNotSupported)
        }

        return .success(())
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .rscMeasurement:
            delegate?.measurementNotificationStatusChanged(enabled)
        case .scControlPoint:
            delegate?.controlPointNotificationStatusChanged(enabled)
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
}
