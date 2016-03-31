/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "GlucoseReading.h"
#import "CharacteristicReader.h"

@implementation GlucoseReading

+ (GlucoseReading *)readingFromBytes:(uint8_t *)bytes
{
    GlucoseReading* reading = [[GlucoseReading alloc] init];
    [reading updateFromBytes:bytes];
    return reading;
}

- (void)updateFromBytes:(uint8_t *)bytes
{
    uint8_t* pointer = bytes;
    
    // Parse flags
    UInt8 flags = [CharacteristicReader readUInt8Value:&pointer];
    BOOL timeOffsetPresent = (flags & 0x01) > 0;
    BOOL glucoseConcentrationTypeAndLocationPresent = (flags & 0x02) > 0;
    BgmUnit glucoseConcentrationUnit = (flags & 0x04) >> 2;
    BOOL statusAnnunciationPresent = (flags & 0x08) > 0;
    
    // Sequence number is used to match the reading with an optional glucose context
    self.sequenceNumber = [CharacteristicReader readUInt16Value:&pointer];
    self.timestamp = [CharacteristicReader readDateTime:&pointer];
    
    if (timeOffsetPresent)
    {
        self.timeOffset = [CharacteristicReader readSInt16Value:&pointer];
    }
    
    self.glucoseConcentrationTypeAndLocationPresent = glucoseConcentrationTypeAndLocationPresent;
    if (glucoseConcentrationTypeAndLocationPresent)
    {
        self.glucoseConcentration = [CharacteristicReader readSFloatValue:&pointer];
        self.unit = glucoseConcentrationUnit;
        
        Nibble typeAndLocation = [CharacteristicReader readNibble:&pointer];
        self.type = typeAndLocation.first;
        self.location = typeAndLocation.second;
    }
    
    self.sensorStatusAnnunciationPresent = statusAnnunciationPresent;
    if (statusAnnunciationPresent)
    {
        self.sensorStatusAnnunciation = [CharacteristicReader readUInt16Value:&pointer];
    }
}

- (NSString *)typeAsString
{
    switch (self.type) {
        case CAPILLARY_WHOLE_BLOOD:
            return @"Capillary Whole blood";
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
