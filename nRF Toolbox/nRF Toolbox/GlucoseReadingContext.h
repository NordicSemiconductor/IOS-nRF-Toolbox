//
//  GlucoseReadingContext.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 20/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    RESERVED_CARBOHYDRATE,
    BREAKFEST,
    LUNCH,
    DINNER,
    SNACK,
    DRINK,
    SUPPER,
    BRUNCH
} BgmCarbohydrateId;

typedef enum
{
    RESERVED_MEAL,
    PREPRANDIAL,
    POSTPRANDIAL,
    FASTING,
    CASUAL,
    BEDTIME
} BgmMeal;

typedef enum
{
    RESERVED_TESTER,
    SELF,
    HEALTH_CARE_PROFESSIONAL,
    LAB_TEST,
    TESTER_NOT_AVAILABLE = 15
} BgmTester;

typedef enum
{
    RESERVED_HEALTH,
    MINOR_HEALTH_ISSUES,
    MAJOR_HEALTH_ISSUES,
    DURING_MENSES,
    UNDER_STRESS,
    NO_HEALTH_ISSUES,
    HEALTH_NOT_AVAILABLE = 15
} BgmHealth;

typedef enum
{
    RESERVED_MEDICATON,
    RAPID_ACTING_INSULIN,
    SHORT_ACTING_INSULIN,
    INTERMEDIATE_ACTING_INSULIN,
    LONG_ACTING_INSULINE,
    PRE_MIXED_INSULINE
} BgmMedicationId;

typedef enum
{
    KILOGRAMS,
    LITERS
} BgmMedicationUnit;

@interface GlucoseReadingContext : NSObject

@property (assign, nonatomic) UInt16 sequenceNumber;
@property (assign, nonatomic) BOOL carbohydratePresent;
@property (assign, nonatomic) BgmCarbohydrateId carbohydrateId;
@property (assign, nonatomic) Float32 carbohydrate; // units of kilograms
@property (assign, nonatomic) BOOL mealPresent;
@property (assign, nonatomic) BgmMeal meal;
@property (assign, nonatomic) BOOL testerAndHealthPresent;
@property (assign, nonatomic) BgmTester tester;
@property (assign, nonatomic) BgmHealth health;
@property (assign, nonatomic) BOOL exercisePresent;
@property (assign, nonatomic) UInt16 exerciseDuration; // in seconds
@property (assign, nonatomic) UInt8 exerciseIntensity; // percentage
@property (assign, nonatomic) BOOL medicationPresent;
@property (assign, nonatomic) BgmMedicationId medicationId;
@property (assign, nonatomic) Float32 medication;
@property (assign, nonatomic) BgmMedicationUnit medicationUnit;
@property (assign, nonatomic) BOOL HbA1cPresent;
@property (assign, nonatomic) Float32 HbA1c; // in percantage

+ (GlucoseReadingContext*) readingContextFromBytes:(uint8_t*) bytes;

- (void) updateFromBytes:(uint8_t *)bytes;

- (NSString*) carbohydrateIdAsString;
- (NSString*) mealIdAsString;
- (NSString*) testerAsString;
- (NSString*) healthAsString;
- (NSString*) medicationIdAsString;

@end
