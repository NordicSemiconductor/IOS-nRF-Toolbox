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

public extension RunningSpeedAndCadence {
    
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
    
    // MARK: RSCSFeatureFlags
    
    enum RSCFeature: RegisterValue, Option, CustomStringConvertible, CaseIterable {
        case instantaneousStrideLengthMeasurement
        case totalDistanceMeasurement
        case walkingOrRunningStatus
        case sensorCalibrationProcedure
        case multipleSensorLocation
        
        public var description: String {
            switch self {
            case .instantaneousStrideLengthMeasurement:
                return "Instantaneous Stride Length Measurement"
            case .totalDistanceMeasurement:
                return "Total Distance Measurement"
            case .walkingOrRunningStatus:
                return "Walking or Running Status"
            case .sensorCalibrationProcedure:
                return "Sensor Calibration Procedure"
            case .multipleSensorLocation:
                return "Multiple Sensor Location"
            }
        }
    }

    // MARK: RSCSMeasurementFlags
    
    struct RSCMeasurementFlags: OptionSet {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let instantaneousStrideLengthPresent = RSCMeasurementFlags(rawValue: 1 << 0)
        public static let totalDistancePresent             = RSCMeasurementFlags(rawValue: 1 << 1)
        public static let walkingOrRunningStatus           = RSCMeasurementFlags(rawValue: 1 << 2)
        
        public static let all: RSCMeasurementFlags = [.instantaneousStrideLengthPresent, .totalDistancePresent, .walkingOrRunningStatus]
        public static let none: RSCMeasurementFlags = []
    }
    
    // MARK: SCControlPointOpCode
    
    enum OpCode: UInt8, CustomStringConvertible {
        case setCumulativeValue                 = 0x01
        case startSensorCalibration             = 0x02
        case updateSensorLocation               = 0x03
        case requestSupportedSensorLocations    = 0x04
        case responseCode                       = 0x10
        
        public var data: Data {
            Data([self.rawValue])
        }

        public var description: String {
            switch self {
            case .setCumulativeValue:
                return "Set Cumulative Value"
            case .startSensorCalibration:
                return "Start Sensor Calibration"
            case .updateSensorLocation:
                return "Update Sensor Location"
            case .requestSupportedSensorLocations:
                return "Request Supported Sensor Locations"
            case .responseCode:
                return "Response Code"
            }
        }
    }
    
    // MARK: SCControlPointResponseCode
    
    enum ResponseCode: UInt8, CustomStringConvertible {
        case success = 0x01
        case opCodeNotSupported = 0x02
        case invalidParameter = 0x03
        case operationFailed = 0x04

        public var description: String {
            switch self {
            case .success:
                return "Success"
            case .opCodeNotSupported:
                return "Op Code Not Supported"
            case .invalidParameter:
                return "Invalid Parameter"
            case .operationFailed:
                return "Operation Failed"
            }
        }
    }
    
    // MARK: SensorLocation
    
    enum SensorLocation: UInt8, CustomStringConvertible, CaseIterable {
        case other, topOfShoe, inShoe, hip, frontWheel, leftCrank, rightCrank, leftPedal, rightPedal, frontHub, rearDropout, chainstay, rearWheel, rearHub, chest, spider, chainRing

        public var description: String {
            switch self {
            case .other: return "Other"
            case .topOfShoe: return "Top of shoe"
            case .inShoe: return "In shoe"
            case .hip: return "Hip"
            case .frontWheel: return "Front wheel"
            case .leftCrank: return "Left crank"
            case .rightCrank: return "Right crank"
            case .leftPedal: return "Left pedal"
            case .rightPedal: return "Right pedal"
            case .frontHub: return "Front hub"
            case .rearDropout: return "Rear dropout"
            case .chainstay: return "Chainstay"
            case .rearWheel: return "Rear wheel"
            case .rearHub: return "Rear hub"
            case .chest: return "Chest"
            case .spider: return "Spider"
            case .chainRing: return "Chain ring"
            }
        }
    }
    
    // MARK: RSCSMeasurement
    
    struct RSCSMeasurement {
        public var flags: RSCMeasurementFlags

        /// Instantaneous Speed. 256 units = 1 meter/second
        public var instantaneousSpeed: UInt16

        /// Instantaneous Cadence. 1 unit = 1 stride/minute
        public var instantaneousCadence: UInt8

        /// Instantaneous Stride Length. 100 units = 1 meter
        public var instantaneousStrideLength: UInt16?

        /// Total Distance. 1 unit = 1 meter
        public var totalDistance: UInt32?
        
        public init(flags: RSCMeasurementFlags, instantaneousSpeed: UInt16, instantaneousCadence: UInt8, instantaneousStrideLength: UInt16?, totalDistance: UInt32?) {
            self.flags = flags
            self.instantaneousSpeed = instantaneousSpeed
            self.instantaneousCadence = instantaneousCadence
            self.instantaneousStrideLength = instantaneousStrideLength
            self.totalDistance = totalDistance
        }

        public init(from data: Data) {
            var flagsRawValue: UInt8 = 0
            data.copyBytes(to: &flagsRawValue, count: 1)
            flags = RSCMeasurementFlags(rawValue: flagsRawValue)

            var offset = 1
            instantaneousSpeed = data.read(offset: offset)
            offset += 2
            
            instantaneousCadence = data.read(offset: offset)
            offset += 1

            if flags.contains(.instantaneousStrideLengthPresent) {
                instantaneousStrideLength = data.read(offset: offset)
                offset += 2
            } else {
                instantaneousStrideLength = nil
            }

            if flags.contains(.totalDistancePresent) {
                totalDistance = data.read(offset: offset)
                offset += 4
            } else {
                totalDistance = nil
            }
        }

        public var data: Data {
            var data = Data()

            data.append(flags.rawValue)
            data = data.appendedValue(instantaneousSpeed)
            data = data.appendedValue(instantaneousCadence)
            
            if flags.contains(.instantaneousStrideLengthPresent) {
                data = data.appendedValue(instantaneousStrideLength!)
            }

            if flags.contains(.totalDistancePresent) {
                data = data.appendedValue(totalDistance!)
            }

            return data
        }
    }
    
    // MARK: SCControlPointResponse

    struct SCControlPointResponse {
        public var opCode: OpCode
        public var responseValue: ResponseCode
        public var parameter: Data?

        public init(opCode: OpCode, responseValue: ResponseCode, parameter: Data?) {
            self.opCode = opCode
            self.responseValue = responseValue
            self.parameter = parameter
        }

        public init?(from data: Data) {
            guard data.count >= 2 else { return nil }
            guard let opCode = OpCode(rawValue: Data(data)[1]) else {
                return nil
            }
            self.opCode = opCode
            guard let responseValue = ResponseCode(rawValue: Data(data)[2]) else {
                return nil
            }
            self.responseValue = responseValue
            if data.count > 3 {
                parameter = Data(data).subdata(in: 3 ..< data.count)
            }
        }

        public var data: Data {
            var data = Data()
            data.append(OpCode.responseCode.data)
            data.append(opCode.data)
            data.append(responseValue.rawValue)
            if let parameter {
                data.append(parameter)
            }
            return data
        }
    }
    
    // MARK: SetCumulativeValueResponse
    
    struct SetCumulativeValueResponse {
        private let response: SCControlPointResponse

        public init(responseCode: ResponseCode) {
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

        public init(responseCode: ResponseCode = .success) {
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

        public init(responseCode: ResponseCode = .success) {
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
        public let locations: [SensorLocation]

        public init(locations: [SensorLocation], responseCode: ResponseCode = .success) {
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
                self.locations = locationData.compactMap { SensorLocation(rawValue: $0) }
            } else {
                self.locations = []
            }
        }

        public var data: Data {
            return response.data
        }
    }
}

// MARK: RSCS

public class RunningSpeedAndCadence {
    public var enabledFeatures: BitField<RunningSpeedAndCadence.RSCFeature> = .all()
    public var sensorLocation: RunningSpeedAndCadence.SensorLocation = .inShoe
    
    var notifySCControlPoint: Bool = false
    private lazy var cancellables = Set<AnyCancellable>()
    
    public init(enabledFeatures: BitField<RunningSpeedAndCadence.RSCFeature>, sensorLocation: RunningSpeedAndCadence.SensorLocation) {
        self.enabledFeatures = enabledFeatures
        self.sensorLocation = sensorLocation
    }
    
    public init() {
        self.enabledFeatures = .all()
        self.sensorLocation = .inShoe
        self.peripheralDelegate.delegate = self
    }

    private var peripheralDelegate = RSCSCBMPeripheralSpecDelegate()
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Running Speed and Cadence sensor",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.runningSpeedCadence]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Running Sensor",
            services: [.runningSpeedCadence],
            delegate: self.peripheralDelegate
        )
        .build()
    
    private var measurement: RSCSMeasurement = RSCSMeasurement(
        flags: .all,
        instantaneousSpeed: UInt16(250 * 2.5), // 2.5 m/s
        instantaneousCadence: 170,
        instantaneousStrideLength: 80,
        totalDistance: 0
    )
    
    private var notifyMeasurement: Bool = false {
        didSet {
            guard notifyMeasurement else {
                cancellables.removeAll()
                return
            }
            
            Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    randomizeMeasurement(flags: .all)
                    peripheral.simulateValueUpdate(self.measurement.data , for: .rscMeasurement)
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: Public methods
    
    public func postMeasurement(_ measurement: RunningSpeedAndCadence.RSCSMeasurement) {
        
    }

    public func randomizeMeasurement(flags: RSCMeasurementFlags? = nil) {
        if let flags {
            self.measurement.flags = flags
        }
        let newIS = UInt16(Int(self.measurement.instantaneousSpeed) + Int.random(in: 0...100) - 50)
        if newIS < 750 && newIS > 250 {
            self.measurement.instantaneousSpeed = newIS
        }
        
        self.measurement.instantaneousCadence = UInt8.random(in: 166 ... 174)
        
        if flags?.contains(.instantaneousStrideLengthPresent) == true {
            self.measurement.instantaneousStrideLength = UInt16.random(in: 75 ... 85)
        }
        
        if flags?.contains(.totalDistancePresent) == true {
            self.measurement.totalDistance = (self.measurement.totalDistance ?? 0) + UInt32.random(in: 1 ... 2)
        }
    }
}

// MARK: - RSCSDelegate

protocol RSCSDelegate: AnyObject {
    func didReceiveSetCumulativeValue( value: UInt32)
    func didReceiveStartSensorCalibration()
    func didReceiveUpdateSensorLocation(_ location: RunningSpeedAndCadence.SensorLocation)
    func didReceiveRequestSupportedSensorLocations()

    func measurementNotificationStatusChanged(_ enabled: Bool)
    func controlPointNotificationStatusChanged(_ enabled: Bool)
}

extension RunningSpeedAndCadence: RSCSDelegate {
    
    func didReceiveSetCumulativeValue(value: UInt32) {
        measurement.totalDistance = value
        peripheral.simulateValueUpdate(SetCumulativeValueResponse(responseCode: .success).data,
                                       for: .scControlPoint)
    }
    
    func didReceiveStartSensorCalibration() {
        peripheral.simulateValueUpdate(StartSensorCalibrationResponse(responseCode: .success).data,
                                       for: .scControlPoint)
    }
    
    func didReceiveUpdateSensorLocation(_ location: RunningSpeedAndCadence.SensorLocation) {
        sensorLocation = location
        peripheral.simulateValueUpdate(UpdateSensorLocationResponse(responseCode: .success).data,
                                       for: .scControlPoint)
    }
    
    func didReceiveRequestSupportedSensorLocations() {
        let locations: [RunningSpeedAndCadence.SensorLocation] = [.chest, .hip, .inShoe, .other, .topOfShoe]
        peripheral.simulateValueUpdate(SupportedSensorLocations(locations: locations).data, for: .scControlPoint)
    }
    
    func measurementNotificationStatusChanged(_ enabled: Bool) {
        notifyMeasurement = enabled
    }
    
    func controlPointNotificationStatusChanged(_ enabled: Bool) {
        notifySCControlPoint = enabled
    }
}

internal extension Data {
    
    func read<R: FixedWidthInteger>(offset: Int = 0) -> R {
        let length = MemoryLayout<R>.size
        assert(offset + length <= count, "Out of range")
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.load(as: R.self) }
    }

    func appendedValue<R: FixedWidthInteger>(_ value: R) -> Data {
        var value = value
        let d = Data(bytes: &value, count: MemoryLayout<R>.size)
        return self + d
    }
}
