//
//  RSCS.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 16/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_Common_Libraries
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database

extension RunningSpeedAndCadence {
    
    enum ErrorCode: UInt8, LocalizedError {
        case procedureAlreadyInProgress = 0x80
        case descriptorImproperlyConfigured = 0x81
        
        public var errorDescription: String? {
            switch self {
            case .procedureAlreadyInProgress:
                return "A SC Control Point request cannot be serviced because a previously triggered SC Control Point operation is still in progress."
            case .descriptorImproperlyConfigured:
                return "The Client Characteristic Configuration descriptor is not configured according to the requirements of the service."
            }
        }
    }
    
    // MARK: SetCumulativeValueResponse
    
    struct SetCumulativeValueResponse {
        private let response: SCControlPointResponse

        public init(responseCode: SCControlPointResponseCode) {
            response = SCControlPointResponse(opCode: .setCumulativeValue, responseValue: responseCode, parameter: nil)
        }

        public init?(from data: Data) {
            guard let response = SCControlPointResponse(from: data), response.opCode == .setCumulativeValue else { return nil }
            self.response = response
        }

        public var data: Data {
            return response.data
        }
    }

    // MARK: StartSensorCalibrationResponse
    
    struct StartSensorCalibrationResponse {
        private let response: SCControlPointResponse

        public init(responseCode: SCControlPointResponseCode = .success) {
            response = SCControlPointResponse(opCode: .startSensorCalibration, responseValue: responseCode, parameter: nil)
        }

        public init?(from data: Data) {
            guard let response = SCControlPointResponse(from: data), response.opCode == .startSensorCalibration else { return nil }
            self.response = response
        }

        public var data: Data {
            return response.data
        }
    }

    // MARK: UpdateSensorLocationResponse
    
    struct UpdateSensorLocationResponse {
        private let response: SCControlPointResponse

        public init(responseCode: SCControlPointResponseCode = .success) {
            response = SCControlPointResponse(opCode: .updateSensorLocation, responseValue: responseCode, parameter: nil)
        }

        public init?(from data: Data) {
            guard let response = SCControlPointResponse(from: data), response.opCode == .updateSensorLocation else { return nil }
            self.response = response
        }

        public var data: Data {
            return response.data
        }
    }

    // MARK: SupportedSensorLocations
    
    struct SupportedSensorLocations {
        private let response: SCControlPointResponse
        public let locations: [RSCSSensorLocation]

        public init(locations: [RSCSSensorLocation], responseCode: SCControlPointResponseCode = .success) {
            self.locations = locations
            var data = Data()
            for location in locations {
                data.append(location.rawValue)
            }
            response = SCControlPointResponse(opCode: .requestSupportedSensorLocations, responseValue: responseCode, parameter: data)
        }

        public init?(from data: Data) {
            guard let response = SCControlPointResponse(from: data) else { return nil }
            guard response.opCode == .requestSupportedSensorLocations else { return nil }
            self.response = response
            if let locationData = response.parameter {
                self.locations = locationData.compactMap { RSCSSensorLocation(rawValue: $0) }
            } else {
                self.locations = []
            }
        }

        public var data: Data {
            return response.data
        }
    }
}

// MARK: - RSCSDelegate

protocol RSCSDelegate: AnyObject {
    func didReceiveSetCumulativeValue( value: UInt32)
    func didReceiveStartSensorCalibration()
    func didReceiveUpdateSensorLocation(_ location: RSCSSensorLocation)
    func didReceiveRequestSupportedSensorLocations()

    func measurementNotificationStatusChanged(_ peripheral: CBMPeripheralSpec, characteristic: CBMCharacteristicMock, enabled: Bool)
    func controlPointNotificationStatusChanged(_ enabled: Bool)
}

extension RunningSpeedAndCadence: RSCSDelegate {
    
    func didReceiveSetCumulativeValue(value: UInt32) {
        measurement.totalDistance = Measurement<UnitLength>(value: Double(value), unit: .meters)
        peripheral.simulateValueUpdate(SetCumulativeValueResponse(responseCode: .success).data,
                                       for: .scControlPoint)
    }
    
    func didReceiveStartSensorCalibration() {
        peripheral.simulateValueUpdate(StartSensorCalibrationResponse(responseCode: .success).data,
                                       for: .scControlPoint)
    }
    
    func didReceiveUpdateSensorLocation(_ location: RSCSSensorLocation) {
        sensorLocation = location
        peripheral.simulateValueUpdate(UpdateSensorLocationResponse(responseCode: .success).data,
                                       for: .scControlPoint)
    }
    
    func didReceiveRequestSupportedSensorLocations() {
        let locations: [RSCSSensorLocation] = [.chest, .hip, .inShoe, .other, .topOfShoe]
        peripheral.simulateValueUpdate(SupportedSensorLocations(locations: locations).data, for: .scControlPoint)
    }
    
    func measurementNotificationStatusChanged(_ peripheral: CBMPeripheralSpec, characteristic: CBMCharacteristicMock, enabled: Bool) {
        notifyMeasurement = enabled
        guard notifyMeasurement else {
            cancellables.removeAll()
            return
        }
        
        Timer.publish(every: 2.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                randomizeMeasurement(flags: .all())
                self.log.debug("Sending \(self.measurement).")
                peripheral.simulateValueUpdate(self.measurement.toData(), for: characteristic)
            }
            .store(in: &cancellables)
    }
    
    func controlPointNotificationStatusChanged(_ enabled: Bool) {
        notifySCControlPoint = enabled
    }
}

internal extension Data {
    
    func appendedValue<R: FixedWidthInteger>(_ value: R) -> Data {
        var value = value
        let d = Data(bytes: &value, count: MemoryLayout<R>.size)
        return self + d
    }
}
