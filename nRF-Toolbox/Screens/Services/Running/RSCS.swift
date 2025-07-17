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
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database

typealias SensorLocation = RunningSpeedAndCadence.SensorLocation
typealias RSCFeature = RunningSpeedAndCadence.RSCFeature
typealias SupportedSensorLocationsResponse = RunningSpeedAndCadence.SupportedSensorLocations

extension CBMUUID {
    
    static let rscMeasurement = CBMUUID(characteristic: .rscMeasurement)
    
    static let rscFeature = CBMUUID(characteristic: .rscFeature)
    static let sensorLocation = CBMUUID(characteristic: .sensorLocation)
    
    static let scControlPoint = CBMUUID(characteristic: .scControlPoint)
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
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
    
    /// RSC Feature. Response to Read RSC Feature Characteristic
    struct RSCFeature: OptionSet {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public static let instantaneousStrideLengthMeasurement = RSCFeature(rawValue: 1 << 0)
        public static let totalDistanceMeasurement             = RSCFeature(rawValue: 1 << 1)
        public static let walkingOrRunningStatus               = RSCFeature(rawValue: 1 << 2)
        public static let sensorCalibrationProcedure           = RSCFeature(rawValue: 1 << 3)
        public static let multipleSensorLocation               = RSCFeature(rawValue: 1 << 4)
        
        public static let all: RSCFeature = [.instantaneousStrideLengthMeasurement, .totalDistanceMeasurement, .walkingOrRunningStatus, .sensorCalibrationProcedure, .multipleSensorLocation]
        public static let none: RSCFeature = []
    }

    /// RSC Measurement Flags
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
    
    /// SC Control Point Op Code
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
    
    /// SC Control Point Response Value
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
    
    /// RSC Measurement characteristic value
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

    /// SC Control Point response value
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

protocol RSCSDelegate: AnyObject {
    func didReceiveSetCumulativeValue( value: UInt32)
    func didReceiveStartSensorCalibration()
    func didReceiveUpdateSensorLocation(_ location: RunningSpeedAndCadence.SensorLocation)
    func didReceiveRequestSupportedSensorLocations()

    func measurementNotificationStatusChanged(_ enabled: Bool)
    func controlPointNotificationStatusChanged(_ enabled: Bool)
}

public class RunningSpeedAndCadence {
    public var enabledFeatures: RunningSpeedAndCadence.RSCFeature = .all
    public var sensorLocation: RunningSpeedAndCadence.SensorLocation = .inShoe
    
    var notifySCControlPoint: Bool = false
    private lazy var cancellables = Set<AnyCancellable>()
    
    public init(enabledFeatures: RunningSpeedAndCadence.RSCFeature, sensorLocation: RunningSpeedAndCadence.SensorLocation) {
        self.enabledFeatures = enabledFeatures
        self.sensorLocation = sensorLocation
    }
    
    public init() {
        self.enabledFeatures = .all
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

fileprivate extension Data {
    
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
