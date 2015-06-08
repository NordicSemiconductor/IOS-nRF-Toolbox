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
