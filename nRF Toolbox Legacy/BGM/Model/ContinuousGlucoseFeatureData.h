//
//  ContinuousGlucoseFeatureData.h
//  nRF Toolbox
//
//  Created by Mostafa Berg on 02/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContinuousGlucoseFeatureData : NSObject

typedef enum
{
    CGMFeatureCalibrationSupport                       = 0,
    CGMFeaturePatientHighLowAlertsSupport              = 1,
    CGMFeatureHypoAlertsSupport                        = 2,
    CGMFeatureHyperAlertsSupport                       = 3,
    CGMFeatureRateofIncreaseDecreaseAlertsSupport      = 4,
    CGMFeatureDeviceSpecificAlertSupport               = 5,
    CGMFeatureSensorMalfunctionDetectionSupport        = 6,
    CGMFeatureSensorTemperatureHighLowDetectionSupport = 7,
    CGMFeatureSensorResultHighLowDetectionSupport      = 8,
    CGMFeatureLowBatteryDetectionSupport               = 9,
    CGMFeatureSensorTypeErrorDetectionSupport          = 10,
    CGMFeatureGeneralDeviceFaultSupport                = 11,
    CGMFeatureE2ECRCSupport                            = 12,
    CGMFeatureMultipleBondSupport                      = 13,
    CGMFeatureMultipleSessionsSupport                  = 14,
    CGMFeatureCGMTrendInformationSupport               = 15,
    CGMFeatureCGMQualitySupport                        = 16,
} CGMFeatureFlags;

typedef enum
{
    CGMTypeCapillaryWholeBlood    = 1,
    CGMTypeCapillaryPlasma        = 2,
    CGMTypeCapillaryWholeBlood2   = 3,
    CGMTypeVenousPlasma           = 4,
    CGMTypeArterialWholeBlood     = 5,
    CGMTypeArterialPlasma         = 6,
    CGMTypeUndeterminedWholeBlood = 7,
    CGMTypeUndeterminedPlasma     = 8,
    CGMTypeInterstitialFluid      = 9,
    CGMTypeControlSolution        = 10,
} CGMType;

typedef enum
{
    CGMLocationFinger             = 1,
    CGMLocationAlternateSiteTest  = 2,
    CGMLocationEarlobe            = 3,
    CGMLocationControlSolution    = 4,
    CGMLocationSubcutaneousTissue = 5,
    CGMLocationValueNotAvailable  = 15,
} CGMLocation;

// Glucose Measurement values
@property (assign, nonatomic) CGMType type;
@property (assign, nonatomic) CGMLocation location;

+ (ContinuousGlucoseFeatureData*) initWithBytes:(uint8_t*) bytes;
- (void) updateFromBytes:(uint8_t*) bytes;
- (NSString*) typeAsString;
- (NSString*) locationAsString;

@end
