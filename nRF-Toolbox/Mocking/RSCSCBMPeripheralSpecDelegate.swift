//
//  RSCSCBMPeripheralSpecDelegate.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 21/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

// MARK: - CoreBluetoothMock

private extension CBMUUID {
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

private extension CBMServiceMock {
    
    static let runningSpeedCadence = CBMServiceMock(
        type: .runningSpeedCadence,
        primary: true,
        characteristics: .rscMeasurement, .rscFeature, .sensorLocation, .scControlPoint
    )
}

// MARK: RSCS

class RSCSCBMPeripheralSpecDelegate: MockSpecDelegate {
    private var enabledFeatures: BitField<RSCSFeature> = .all()
    private var sensorLocation: RSCSSensorLocation = .inShoe
    private var notifyMeasurement: Bool = false
    
    private var notifySCControlPoint: Bool = false
    
    private let log = NordicLog(category: "RunningSpeedAndCadence")
    private var timerCancellable: AnyCancellable?
    
    public init(enabledFeatures: BitField<RSCSFeature>, sensorLocation: RSCSSensorLocation) {
        self.enabledFeatures = enabledFeatures
        self.sensorLocation = sensorLocation
    }
    
    public init() {
        self.enabledFeatures = .all()
        self.sensorLocation = .inShoe
    }

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
            delegate: self,
            connectionInterval: 0.0,
        )
        .build()
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .runningSpeedCadence
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, Error> {
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
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        switch characteristic.uuid {
        case CBMUUID.scControlPoint:
            let opCode = SCControlPointOpCode(rawValue: UInt8(data.littleEndianBytes(as: UInt8.self)))!
            switch opCode {
            case .setCumulativeValue:
                let value: UInt32 = UInt32(data.littleEndianBytes(as: UInt32.self))
                didReceiveSetCumulativeValue(peripheral, value: value)
            case .startSensorCalibration:
                didReceiveStartSensorCalibration(peripheral)
            case .updateSensorLocation:
                let location = RSCSSensorLocation(rawValue: UInt8(data.littleEndianBytes(as: UInt8.self)))!
                didReceiveUpdateSensorLocation(peripheral, location)
            case .requestSupportedSensorLocations:
                didReceiveRequestSupportedSensorLocations(peripheral)
            default:
                return .failure(MockError.writingIsNotSupported)
            }
        default:
            return .failure(MockError.writingIsNotSupported)
        }
        return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .rscMeasurement:
            measurementNotificationStatusChanged(peripheral, characteristic: characteristic, enabled: enabled)
        case .scControlPoint:
            controlPointNotificationStatusChanged(enabled)
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: (any Error)?) {
        log.debug(#function)
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func random(flags: BitField<RSCSFeature> = .all()) -> RSCSMeasurement {
        var measurement = RSCSMeasurement(
            flags: flags,
            instantaneousSpeed: 2.5,
            instantaneousCadence: 170,
            instantaneousStrideLength: 80,
            totalDistance: 0
        )
        
        let newIS = Double.random(in: 0...3)
        measurement.instantaneousSpeed = Measurement<UnitSpeed>(value: newIS, unit: .metersPerSecond)
        measurement.instantaneousCadence = Int.random(in: 166 ... 174)
        
        if flags.contains(.instantaneousStrideLengthMeasurement) {
            let value = Int.random(in: 75 ... 85)
            measurement.instantaneousStrideLength = Measurement<UnitLength>(value: Double(value), unit: .centimeters)
        }
        
        if flags.contains(.totalDistanceMeasurement), let distanceValue = measurement.totalDistance?.value {
            measurement.totalDistance =
                Measurement<UnitLength>(value: distanceValue + Double.random(in: 1...2), unit: .meters)
        }
        return measurement
    }
    
    private func didReceiveSetCumulativeValue(_ peripheral: CBMPeripheralSpec, value: UInt32) {
        var measurement: RSCSMeasurement = random()
        measurement.totalDistance = Measurement<UnitLength>(value: Double(value), unit: .meters)
        peripheral.simulateValueUpdate(SetCumulativeValueResponse(responseCode: .success).data, for: .scControlPoint)
    }
    
    private func didReceiveStartSensorCalibration(_ peripheral: CBMPeripheralSpec) {
        peripheral.simulateValueUpdate(StartSensorCalibrationResponse(responseCode: .success).data, for: .scControlPoint)
    }
    
    private func didReceiveUpdateSensorLocation(_ peripheral: CBMPeripheralSpec, _ location: RSCSSensorLocation) {
        sensorLocation = location
        peripheral.simulateValueUpdate(UpdateSensorLocationResponse(responseCode: .success).data, for: .scControlPoint)
    }
    
    private func didReceiveRequestSupportedSensorLocations(_ peripheral: CBMPeripheralSpec) {
        let locations: [RSCSSensorLocation] = [.chest, .hip, .inShoe, .other, .topOfShoe]
        peripheral.simulateValueUpdate(SupportedSensorLocations(locations: locations).data, for: .scControlPoint)
    }
    
    private func measurementNotificationStatusChanged(_ peripheral: CBMPeripheralSpec, characteristic: CBMCharacteristicMock, enabled: Bool) {
        notifyMeasurement = enabled
        if timerCancellable == nil {
            timerCancellable = Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    let newMeasurement: RSCSMeasurement = random()
                    self.log.debug("Sending \(newMeasurement).")
                    peripheral.simulateValueUpdate(newMeasurement.toData(), for: characteristic)
                }
        }
    }
    
    private func controlPointNotificationStatusChanged(_ enabled: Bool) {
        notifySCControlPoint = enabled
    }
}
