//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum  CGMMeasurementUnit : UInt8 {
    case mg_DL = 0
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

class NORCGMReading : NSObject {
    // Glucose Measurement values
    var cgmFeatureData                  : NORCGMFeatureData?
    var measurementSize                 : UInt8 = 0
    var timeStamp                       : Date?
    var timeOffsetSinceSessionStart     : Int16 = 0
    var glucoseConcentration            : Float32 = 0.0
    var trendInfo                       : Float32 = 0.0
    var quality                         : Float32 = 0.0
    var sensorStatusAnnunciation        : UInt32 = 0
    var unit                            : CGMMeasurementUnit  = .mg_DL
    var sensorStatusAnnunciationPresent : Bool = false
    var sensorTrendInfoPresent          : Bool = false
    var sensorWarningPresent            : Bool = false
    var sensorCalTempPresent            : Bool = false
    var sensorQualityPresent            : Bool = false
    var e2eCrcPresent                   : Bool = false
    
    required init(withBytes bytes : UnsafeMutablePointer<UInt8>) {
        super.init()
        self.updateFromBytes(bytes)
    }

    func updateFromBytes(_ bytes: UnsafeMutablePointer<UInt8>) {
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
        self.unit                        = .mg_DL
        self.timeOffsetSinceSessionStart = NORCharacteristicReader.readSInt16Value(ptr: &pointer)
        self.sensorCalTempPresent        = statusCalTempPsesent;
        self.sensorWarningPresent        = statusWarningPsesent;
        
        self.sensorStatusAnnunciationPresent = statusAnnunciationPresent;
        if (self.sensorStatusAnnunciationPresent)
        {
            self.sensorStatusAnnunciation = NORCharacteristicReader.readUInt32Value(ptr: &pointer)
        }
        
        self.sensorTrendInfoPresent = trendInfoPresent;
        if(self.sensorTrendInfoPresent)
        {
            self.trendInfo = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        }
        self.sensorQualityPresent = qualityPresent;
        
        if(self.sensorQualityPresent){
            self.quality = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        }
        self.e2eCrcPresent = false;
    }
    
    func typeAsString() ->String {
        guard self.cgmFeatureData != nil else {
            return "N/A"
        }
        return (self.cgmFeatureData?.typeAsString())!
    }
    
    func locationAsSting() -> String {
        guard self.cgmFeatureData != nil else {
            return "N/A"
        }
        return (self.cgmFeatureData?.locationAsString())!
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        //TODO: Thought about using time offset as unique identifiers
        //But this is pretty unsafe in situations where the readings are restarted
        //In that case the time offsets will be equal again (0s,1s,2s,etc..)
        //Will assume not equal for now
        return false
    }
}
