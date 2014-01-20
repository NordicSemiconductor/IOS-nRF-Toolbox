//
//  GlucoseReading.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 17/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "GlucoseReading.h"
#import "CharacteristicReader.h"

@implementation GlucoseReading

+ (GlucoseReading *)readingWFromBytes:(uint8_t *)bytes
{
    GlucoseReading* reading = [[GlucoseReading alloc] init];
    uint8_t* pointer = bytes;
    
    // Parse flags
    UInt8 flags = [CharacteristicReader readUInt8Value:&pointer];
    BOOL timeOffsetPresent = (flags & 0x01) > 0;
    BOOL glucoseConcentrationTypeAndLocationPresent = (flags & 0x02) > 0;
    BgmUnit glucoseConcentrationUnit = (flags & 0x04) >> 2;
    BOOL statusAnnunciationPresent = (flags & 0x08) > 0;
    
    // We will use the sequence number to match the reading with (optional) following glucose context
    reading.sequenceNumber = [CharacteristicReader readUInt16Value:&pointer];
    reading.timestamp = [CharacteristicReader readDateTime:&pointer];
    
    if (timeOffsetPresent)
    {
        reading.timeOffset = [CharacteristicReader readSInt16Value:&pointer];
    }
    
    if (glucoseConcentrationTypeAndLocationPresent)
    {
        reading.glucoseConcentration = [CharacteristicReader readSFloatValue:&pointer] * 1000;
        reading.unit = glucoseConcentrationUnit;
        
        Nibble typeAndLocation = [CharacteristicReader readNibble:&pointer];
        reading.type = typeAndLocation.first;
        reading.location = typeAndLocation.second;
    }
    
    if (statusAnnunciationPresent)
    {
        reading.sensorStatusAnnunciation = [CharacteristicReader readUInt16Value:&pointer];
    }
    
    return reading;
}

- (NSString *)typeAsString
{
    switch (self.type) {
        case CAPILLARY_WHOLE_BLOOD:
            return @"Capillary Whole boood";
        case CAPILLARY_PLASMA:
            return @"Capillary Plasma";
        case VENOUS_WHOLE_BLOOD:
            return @"Venous Whole blood";
        case VENOUS_PLASMA:
            return @"Venous Plasma";
        case ARTERIAL_WHOLE_BLOOD:
            return @"Arterial Whole blood";
        case ARTERIAL_PLASMA:
            return @"Arterial Plasma";
        case UNDETERMINED_WHOLE_BLOOD:
            return @"Undetermined Whole blood";
        case UNDETERMINED_PLASMA:
            return @"Undetermined Plasma";
        case INTERSTITIAL_FLUID:
            return @"Interstellar fluid (ISF)";
        case CONTROL_SOLUTION_TYPE:
            return @"Control Point";
        default:
            return [NSString stringWithFormat:@"Reserved: %d", self.type];
    }
}

- (NSString *)locationAsString
{
    switch (self.location) {
        case FINGER:
            return @"Finger";
        case ALTERNATE_SITE_TEST:
            return @"Alternate Site Test (AST)";
        case EARLOBE:
            return @"Earlobe";
        case CONTROL_SOLUTION_LOCATION:
            return @"Contrl Point";
        case LOCATION_NOT_AVAILABLE:
            return @"Not available";
        default:
            return [NSString stringWithFormat:@"Reserved: %d", self.location];
    }
}

- (BOOL)isEqual:(id)object
{
    GlucoseReading* reading = (GlucoseReading*) object;
    return self.sequenceNumber == reading.sequenceNumber;
}

@end
