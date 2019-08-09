//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum  CGMMeasurementUnit : UInt8 {
    case mgDl = 0
}

enum CGMFlags : UInt8 {
    case cgmTrendInfoPresent                 = 0
    case cgmQualityInfoPresent               = 1
    case cgmSesnorStatusWarningPresent       = 5
    case cgmSensorStatusCalTempOctetPresent  = 6
    case cgmSensorStatusStatusOctetPresent   = 7
}

enum CGMSensorAnnuciation : UInt8 {
    case cgmSessionStopped 								= 0
    case cgmDeviceBatteryLow 							= 1
    case cgmSensorTypeIncorrectForDevice 				= 2
    case cgmSensorMalfunction 							= 3
    case cgmDeviceSpecificAlert 						= 4
    case cgmGeneralDeviceFaultOccurredInSensor 			= 5
    case cgmTimeSynchronizationRequired 				= 8
    case cgmCalibrationNotAllowed 						= 9
    case cgmCalibrationRecommended 						= 10
    case cgmCalibrationRequired 						= 11
    case cgmSensorTemperatureTooHighForValidMeasurement = 12
    case cgmSensorTemperatureTooLowForValidMeasurement	= 13
    case cgmSensorResultLowerThanPatientLowLevel 		= 16
    case cgmSensorResultHigherThanPatientHighLevel 		= 17
    case cgmSensorResultLowerThanHypoLevel 				= 18
    case cgmSensorResultHigherThanHyperLevel 			= 19
    case cgmSensorRateOfDecreaseExceeded 				= 20
    case cgmSensorRateOfIncreaseExceeded 				= 21
    case cgmSensorResultLowerThanTheDeviceCanProcess 	= 22
    case cgmSensorResultHigherThanTheDeviceCanProcess 	= 23
}

struct NORCGMReading {
    // Glucose Measurement values
    var cgmFeatureData                  : NORCGMFeatureData?
    let measurementSize                 : UInt8
    let timeOffsetSinceSessionStart     : TimeInterval
    let glucoseConcentration            : Float32
    let trendInfo                       : Float32?
    let quality                         : Float32?
    let sensorStatusAnnunciation        : UInt32?
    let unit                            : CGMMeasurementUnit
    let sensorStatusAnnunciationPresent : Bool
    let sensorTrendInfoPresent          : Bool
    let sensorWarningPresent            : Bool
    let sensorCalTempPresent            : Bool
    let sensorQualityPresent            : Bool
    let e2eCrcPresent                   : Bool
    
    init(_ bytes : UnsafeMutablePointer<UInt8>) {
        var pointer = bytes;
        
        // Read measurement Length
        let currentMeasurementSize = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
        
        // Parse flags
        let flags = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
        
        let trendInfoPresent           = (flags & 0x01) > 0
        let qualityPresent             = (flags & 0x02) > 0
        let statusWarningPsesent       = (flags & 0x20) > 0
        let statusCalTempPsesent       = (flags & 0x40) > 0
        let statusAnnunciationPresent  = (flags & 0x80) > 0
        
        self.measurementSize             = currentMeasurementSize;
        self.glucoseConcentration        = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        self.unit                        = .mgDl
        self.timeOffsetSinceSessionStart = TimeInterval(60 * NORCharacteristicReader.readSInt16Value(ptr: &pointer))
        self.sensorCalTempPresent        = statusCalTempPsesent;
        self.sensorWarningPresent        = statusWarningPsesent;
        
        self.sensorStatusAnnunciationPresent = statusAnnunciationPresent;
        if self.sensorStatusAnnunciationPresent {
            self.sensorStatusAnnunciation = NORCharacteristicReader.readUInt32Value(ptr: &pointer)
        } else {
            self.sensorStatusAnnunciation = nil
        }
        
        self.sensorTrendInfoPresent = trendInfoPresent;
        if self.sensorTrendInfoPresent {
            self.trendInfo = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        } else {
            self.trendInfo = nil
        }
        self.sensorQualityPresent = qualityPresent;
        
        if self.sensorQualityPresent {
            self.quality = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        } else {
            self.quality = nil
        }
        // E2E CRC is not supported.
        self.e2eCrcPresent = false;
    }
    
    func typeAsString() ->String {
        guard let data = cgmFeatureData else {
            return "N/A"
        }
        return "\(data.type)"
    }
    
    func locationAsSting() -> String {
        guard let data = cgmFeatureData else {
            return "N/A"
        }
        return "\(data.location)"
    }
}

extension NORCGMReading: Equatable {
    
    static func == (lhs: NORCGMReading, rhs: NORCGMReading) -> Bool {
        return lhs.timeOffsetSinceSessionStart == rhs.timeOffsetSinceSessionStart
    }
    
}
