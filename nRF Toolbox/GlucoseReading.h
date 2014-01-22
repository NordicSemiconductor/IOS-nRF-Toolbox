//
//  GlucoseReading.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 17/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

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
