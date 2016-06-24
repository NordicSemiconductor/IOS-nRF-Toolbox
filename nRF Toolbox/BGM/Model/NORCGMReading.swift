//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum  CGMMeasurementUnit : UInt8 {
    case MG_DL = 0
}

enum CGMFlags : UInt8 {
    case CGMTrendInfoPresent                 = 0
    case CGMQualityInfoPresent               = 1
    case CGMSesnorStatusWarningPresent       = 5
    case CGMSensorStatusCalTempOctetPresent  = 6
    case CGMSensorStatusStatusOctetPresent   = 7
}

enum CGMSensorAnnuciation : UInt8 {
    case CGMSessionStopped 								= 0
    case CGMDeviceBatteryLow 							= 1
    case CGMSensorTypeIncorrectForDevice 				= 2
    case CGMSensorMalfunction 							= 3
    case CGMDeviceSpecificAlert 						= 4
    case CGMGeneralDeviceFaultOccurredInSensor 			= 5
    case CGMTimeSynchronizationRequired 				= 8
    case CGMCalibrationNotAllowed 						= 9
    case CGMCalibrationRecommended 						= 10
    case CGMCalibrationRequired 						= 11
    case CGMSensorTemperatureTooHighForValidMeasurement = 12
    case CGMSensorTemperatureTooLowForValidMeasurement	= 13
    case CGMSensorResultLowerThanPatientLowLevel 		= 16
    case CGMSensorResultHigherThanPatientHighLevel 		= 17
    case CGMSensorResultLowerThanHypoLevel 				= 18
    case CGMSensorResultHigherThanHyperLevel 			= 19
    case CGMSensorRateOfDecreaseExceeded 				= 20
    case CGMSensorRateOfIncreaseExceeded 				= 21
    case CGMSensorResultLowerThanTheDeviceCanProcess 	= 22
    case CGMSensorResultHigherThanTheDeviceCanProcess 	= 23
}

class NORCGMReading : NSObject {
    // Glucose Measurement values
    var cgmFeatureData                  : NORCGMFeatureData?
    var measurementSize                 : UInt8 = 0
    var timeStamp                       : NSDate?
    var timeOffsetSinceSessionStart     : Int16 = 0
    var glucoseConcentration            : Float32 = 0.0
    var trendInfo                       : Float32 = 0.0
    var quality                         : Float32 = 0.0
    var sensorStatusAnnunciation        : UInt32 = 0
    var unit                            : CGMMeasurementUnit  = .MG_DL
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

    func updateFromBytes(bytes: UnsafeMutablePointer<UInt8>) {
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
        self.unit                        = .MG_DL
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
    
    override func isEqual(object: AnyObject?) -> Bool {
        //TODO: Thought about using time offset as unique identifiers
        //But this is pretty unsafe in situations where the readings are restarted
        //In that case the time offsets will be equal again (0s,1s,2s,etc..)
        //Will assume not equal for now
        return false
    }
}
