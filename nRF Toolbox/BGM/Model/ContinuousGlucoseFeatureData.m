//
//  ContinuousGlucoseFeatureData.m
//  nRF Toolbox
//
//  Created by Mostafa Berg on 02/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

#import "ContinuousGlucoseFeatureData.h"
#import "CharacteristicReader.h"

@implementation ContinuousGlucoseFeatureData

+ (ContinuousGlucoseFeatureData*) initWithBytes:(uint8_t*) bytes {
    
    ContinuousGlucoseFeatureData* data = [ContinuousGlucoseFeatureData alloc];
    [data updateFromBytes:bytes];
    return data;
    
}

- (void) updateFromBytes:(uint8_t*) bytes {
    uint8_t* pointer = bytes;
    
    // Parse flags
    pointer += 3; //Skip flags

    Nibble typeAndLocation = [CharacteristicReader readNibble:&pointer];
    self.type = typeAndLocation.second;
    self.location = typeAndLocation.first;
}

- (NSString *)typeAsString
{
    switch (self.type) {
        case(CGMTypeCapillaryWholeBlood):
            return @"Capillay whole blood";
            break;
        case(CGMTypeCapillaryPlasma):
            return @"Capillary Plasma";
            break;
        case(CGMTypeCapillaryWholeBlood2):
            return @"Capillary whole blood";
            break;
        case(CGMTypeVenousPlasma):
            return @"Venous plasma";
            break;
        case(CGMTypeArterialWholeBlood):
            return @"Arterial whole blood";
            break;
        case(CGMTypeArterialPlasma):
            return @"Arterial Plasma";
            break;
        case(CGMTypeUndeterminedWholeBlood):
            return @"Undetermined whole blood";
            break;
        case(CGMTypeUndeterminedPlasma):
            return @"Underetmined plasma";
            break;
        case(CGMTypeInterstitialFluid):
            return @"Interstitial fluid";
            break;
        case(CGMTypeControlSolution):
            return @"Control Solution";
            break;
        default:
            return [NSString stringWithFormat:@"Reserved: %d", self.type];
            break;
    }
}

- (NSString *)locationAsString
{
    switch (self.location) {
        case (CGMLocationFinger):
            return @"Finger";
            break;
        case (CGMLocationAlternateSiteTest):
            return @"Alternate site test";
            break;
        case (CGMLocationEarlobe):
            return @"Earlobe";
            break;
        case (CGMLocationControlSolution):
            return @"Control solution";
            break;
        case (CGMLocationSubcutaneousTissue):
            return @"Subcutaneous tissue";
            break;
        case (CGMLocationValueNotAvailable):
            return @"Location Not available";
            break;
        default:
            return [NSString stringWithFormat:@"Reserved: %d", self.location];
    }
}


@end
