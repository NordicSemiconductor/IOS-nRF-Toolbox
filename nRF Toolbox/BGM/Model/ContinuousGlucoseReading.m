//
//  ContinuousGlucoseReading.m
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

#import "ContinuousGlucoseReading.h"
#import "CharacteristicReader.h"

@implementation ContinuousGlucoseReading

+ (ContinuousGlucoseReading *)readingFromBytes:(uint8_t *)bytes
{
    ContinuousGlucoseReading* reading = [[ContinuousGlucoseReading alloc] init];
    [reading updateFromBytes:bytes];
    return reading;
}

- (void)updateFromBytes:(uint8_t *)bytes
{

    uint8_t* pointer = bytes;

    // Default value(s)
    CgmMeasurementUnit measurementUnit = MG_DL;
    
    // Read measurement Length
    UInt8 currentMeasurementSize = [CharacteristicReader readUInt8Value:&pointer];
    
    // Parse flags
    UInt8 flags = [CharacteristicReader readUInt8Value:&pointer];
    
    BOOL trendInfoPresent           = (flags & 0x01) > 0;
    BOOL qualityPresent             = (flags & 0x02) > 0;
    BOOL statusWarningPsesent       = (flags & 0x20) > 0;
    BOOL statusCalTempPsesent       = (flags & 0x40) > 0;
    BOOL statusAnnunciationPresent  = (flags & 0x80) > 0;

    self.measurementSize             = currentMeasurementSize;
    self.glucoseConcentration        = [CharacteristicReader readSFloatValue:&pointer];
    self.unit                        = measurementUnit;
    self.timeOffsetSinceSessionStart = [CharacteristicReader readUInt16Value:&pointer];
    self.sensorCalTempPresent        = statusCalTempPsesent;
    self.sensorWarningPresent        = statusWarningPsesent;

    self.sensorStatusAnnunciationPresent = statusAnnunciationPresent;
    if (self.sensorStatusAnnunciationPresent)
    {
        self.sensorStatusAnnunciation = [CharacteristicReader readUInt32Value:&pointer];
    }
    
    self.sensorTrendInfoPresent = trendInfoPresent;
    if(self.sensorTrendInfoPresent)
    {
        self.trendInfo = [CharacteristicReader readSFloatValue:&pointer];
    }
    self.sensorQualityPresent = qualityPresent;
    if(self.sensorQualityPresent){
        self.quality = [CharacteristicReader readSFloatValue:&pointer];
    }
    self.e2eCrcPresent = false;

}

//- (NSString *)typeAsString
//{
//    switch (self.type) {
//        case CAPILLARY_WHOLE_BLOOD:
//            return @"Capillary Whole blood";
//        case CAPILLARY_PLASMA:
//            return @"Capillary Plasma";
//        case VENOUS_WHOLE_BLOOD:
//            return @"Venous Whole blood";
//        case VENOUS_PLASMA:
//            return @"Venous Plasma";
//        case ARTERIAL_WHOLE_BLOOD:
//            return @"Arterial Whole blood";
//        case ARTERIAL_PLASMA:
//            return @"Arterial Plasma";
//        case UNDETERMINED_WHOLE_BLOOD:
//            return @"Undetermined Whole blood";
//        case UNDETERMINED_PLASMA:
//            return @"Undetermined Plasma";
//        case INTERSTITIAL_FLUID:
//            return @"Interstellar fluid (ISF)";
//        case CONTROL_SOLUTION_TYPE:
//            return @"Control Point";
//        default:
//            return [NSString stringWithFormat:@"Reserved: %d", self.type];
//    }
//}

//- (NSString *)locationAsString
//{
//    switch (self.location) {
//        case FINGER:
//            return @"Finger";
//        case ALTERNATE_SITE_TEST:
//            return @"Alternate Site Test (AST)";
//        case EARLOBE:
//            return @"Earlobe";
//        case CONTROL_SOLUTION_LOCATION:
//            return @"Contrl Point";
//        case LOCATION_NOT_AVAILABLE:
//            return @"Not available";
//        default:
//            return [NSString stringWithFormat:@"Reserved: %d", self.location];
//    }
//}

- (BOOL)isEqual:(id)object
{
    //TODO: Thought about using time offset as unique identifiers
    //But this is pretty unsafe in situations where the readings are restarted
    //In that case the time offsets will be equal again (0s,1s,2s,etc..)
    //Will assume not equal for now
    return NO;

    //    ContinuousGlucoseReading* reading = (ContinuousGlucoseReading*) object;
    //    return self.timeOffsetSinceSessionStart == reading.timeOffsetSinceSessionStart;
}

@end

