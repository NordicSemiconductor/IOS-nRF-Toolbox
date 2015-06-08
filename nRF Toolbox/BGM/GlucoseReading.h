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

#import <Foundation/Foundation.h>
#import "GlucoseReadingContext.h"

typedef enum
{
    KG_L,
    MOL_L
} BgmUnit;

typedef enum
{
    RESERVED_TYPE,
    CAPILLARY_WHOLE_BLOOD,
    CAPILLARY_PLASMA,
    VENOUS_WHOLE_BLOOD,
    VENOUS_PLASMA,
    ARTERIAL_WHOLE_BLOOD,
    ARTERIAL_PLASMA,
    UNDETERMINED_WHOLE_BLOOD,
    UNDETERMINED_PLASMA,
    INTERSTITIAL_FLUID,
    CONTROL_SOLUTION_TYPE
} BgmType;

typedef enum
{
    RESERVED_LOCATION,
    FINGER,
    ALTERNATE_SITE_TEST,
    EARLOBE,
    CONTROL_SOLUTION_LOCATION,
    LOCATION_NOT_AVAILABLE = 15
} BgmLocation;

@interface GlucoseReading : NSObject

// Glucose Measurement values
@property (assign, nonatomic) UInt16 sequenceNumber;
@property (strong, nonatomic) NSDate* timestamp;
@property (assign, nonatomic) SInt16 timeOffset;
@property (assign, nonatomic) BOOL glucoseConcentrationTypeAndLocationPresent;
@property (assign, nonatomic) Float32 glucoseConcentration;
@property (assign, nonatomic) BgmUnit unit;
@property (assign, nonatomic) BgmType type;
@property (assign, nonatomic) BgmLocation location;
@property (assign, nonatomic) BOOL sensorStatusAnnunciationPresent;
@property (assign, nonatomic) UInt16 sensorStatusAnnunciation;

// Glucose Measurement Context values
@property (strong, nonatomic) GlucoseReadingContext* context;

+ (GlucoseReading*) readingFromBytes:(uint8_t*) bytes;

- (void) updateFromBytes:(uint8_t*) bytes;

- (NSString*) typeAsString;

- (NSString*) locationAsString;

@end
