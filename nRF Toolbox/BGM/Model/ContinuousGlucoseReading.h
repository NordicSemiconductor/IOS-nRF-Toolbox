//
//  ContinuousGlucoseReading.h
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContinuousGlucoseFeatureData.h"
typedef enum
{
    MG_DL = 0,
} CgmMeasurementUnit;

typedef enum
{
    CGMTrendInfoPresent                 = 0,
    CGMQualityInfoPresent               = 1,
    CGMSesnorStatusWarningPresent       = 5,
    CGMSensorStatusCalTempOctetPresent  = 6,
    CGMSensorStatusStatusOctetPresent   = 7,
} CgmFlags;

typedef enum
{
    CGMSessionStopped 								= 0,
    CGMDeviceBatteryLow 							= 1,
    CGMSensorTypeIncorrectForDevice 				= 2,
    CGMSensorMalfunction 							= 3,
    CGMDeviceSpecificAlert 							= 4,
    CGMGeneralDeviceFaultOccurredInSensor 			= 5,
    CGMTimeSynchronizationRequired 					= 8,
    CGMCalibrationNotAllowed 						= 9,
    CGMCalibrationRecommended 						= 10,
    CGMCalibrationRequired 							= 11,
    CGMSensorTemperatureTooHighForValidMeasurement 	= 12,
    CGMSensorTemperatureTooLowForValidMeasurement	= 13,
    CGMSensorResultLowerThanPatientLowLevel 		= 16,
    CGMSensorResultHigherThanPatientHighLevel 		= 16,
    CGMSensorResultLowerThanHypoLevel 				= 18,
    CGMSensorResultHigherThanHyperLevel 			= 19,
    CGMSensorRateOfDecreaseExceeded 				= 20,
    CGMSensorRateOfIncreaseExceeded 				= 21,
    CGMSensorResultLowerThanTheDeviceCanProcess 	= 22,
    CGMSensorResultHigherThanTheDeviceCanProcess 	= 23,
} CGMSensorAnnuciation;

@interface ContinuousGlucoseReading : NSObject

// Glucose Measurement values
@property (weak, nonatomic)   ContinuousGlucoseFeatureData* CGMfeatureData;
@property (assign, nonatomic) UInt8 measurementSize;
@property (strong, nonatomic) NSDate* timesStamp;
@property (assign, nonatomic) SInt16 timeOffsetSinceSessionStart;
@property (assign, nonatomic) Float32 glucoseConcentration;
@property (assign, nonatomic) Float32 trendInfo;
@property (assign, nonatomic) Float32 quality;
@property (assign, nonatomic) UInt32 sensorStatusAnnunciation;
@property (assign, nonatomic) CgmMeasurementUnit unit;
@property (assign, nonatomic) BOOL sensorStatusAnnunciationPresent;
@property (assign, nonatomic) BOOL sensorTrendInfoPresent;
@property (assign, nonatomic) BOOL sensorWarningPresent;
@property (assign, nonatomic) BOOL sensorCalTempPresent;
@property (assign, nonatomic) BOOL sensorQualityPresent;
@property (assign, nonatomic) BOOL e2eCrcPresent;

+ (ContinuousGlucoseReading*) readingFromBytes:(uint8_t*) bytes;
- (void) updateFromBytes:(uint8_t*) bytes;
- (NSString*) typeAsString;
- (NSString*) locationAsString;

@end
