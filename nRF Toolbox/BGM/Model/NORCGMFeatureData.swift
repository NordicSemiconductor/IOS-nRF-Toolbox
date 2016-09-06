//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum CGMFeatureFlags : UInt8 {
    case CGMFeatureCalibrationSupport                       = 0
    case CGMFeaturePatientHighLowAlertsSupport              = 1
    case CGMFeatureHypoAlertsSupport                        = 2
    case CGMFeatureHyperAlertsSupport                       = 3
    case CGMFeatureRateofIncreaseDecreaseAlertsSupport      = 4
    case CGMFeatureDeviceSpecificAlertSupport               = 5
    case CGMFeatureSensorMalfunctionDetectionSupport        = 6
    case CGMFeatureSensorTemperatureHighLowDetectionSupport = 7
    case CGMFeatureSensorResultHighLowDetectionSupport      = 8
    case CGMFeatureLowBatteryDetectionSupport               = 9
    case CGMFeatureSensorTypeErrorDetectionSupport          = 10
    case CGMFeatureGeneralDeviceFaultSupport                = 11
    case CGMFeatureE2ECRCSupport                            = 12
    case CGMFeatureMultipleBondSupport                      = 13
    case CGMFeatureMultipleSessionsSupport                  = 14
    case CGMFeatureCGMTrendInformationSupport               = 15
    case CGMFeatureCGMQualitySupport                        = 16
}

enum CGMType : UInt8 {
    case CGMTypeCapillaryWholeBlood    = 1
    case CGMTypeCapillaryPlasma        = 2
    case CGMTypeCapillaryWholeBlood2   = 3
    case CGMTypeVenousPlasma           = 4
    case CGMTypeArterialWholeBlood     = 5
    case CGMTypeArterialPlasma         = 6
    case CGMTypeUndeterminedWholeBlood = 7
    case CGMTypeUndeterminedPlasma     = 8
    case CGMTypeInterstitialFluid      = 9
    case CGMTypeControlSolution        = 10
}

enum CGMLocation : UInt8{
    case CGMLocationFinger             = 1
    case CGMLocationAlternateSiteTest  = 2
    case CGMLocationEarlobe            = 3
    case CGMLocationControlSolution    = 4
    case CGMLocationSubcutaneousTissue = 5
    case CGMLocationValueNotAvailable  = 15
}


//+ (ContinuousGlucoseFeatureData*) initWithBytes:(uint8_t*) bytes;
//- (void) updateFromBytes:(uint8_t*) bytes;

class NORCGMFeatureData: NSObject {
    // Glucose Measurement values
    var type     : CGMType?
    var location : CGMLocation?

    required init(withBytes bytes: UnsafeMutablePointer<UInt8>) {
        super.init()
        self.updateFromBytes(bytes)
    }
    
    func updateFromBytes(bytes : UnsafeMutablePointer<UInt8>) {

        var pointer = bytes
        pointer += 3 //Skip flags

        let typeAndLocation = NORCharacteristicReader.readNibble(ptr: &pointer)
        self.type = CGMType(rawValue: typeAndLocation.second)!
        self.location = CGMLocation(rawValue: typeAndLocation.first)!

    }

    func typeAsString() -> String {
        switch self.type! {
        case .CGMTypeCapillaryWholeBlood:
            return "Capillay whole blood"
            
        case .CGMTypeCapillaryPlasma:
            return "Capillary Plasma"
            
        case .CGMTypeCapillaryWholeBlood2:
            return "Capillary whole blood"
            
        case .CGMTypeVenousPlasma:
            return "Venous plasma"
            
        case .CGMTypeArterialWholeBlood:
            return "Arterial whole blood"
            
        case .CGMTypeArterialPlasma:
            return "Arterial Plasma"
            
        case .CGMTypeUndeterminedWholeBlood:
            return "Undetermined whole blood"
            
        case .CGMTypeUndeterminedPlasma:
            return "Underetmined plasma"
            
        case .CGMTypeInterstitialFluid:
            return "Interstitial fluid"
            
        case .CGMTypeControlSolution:
            return "Control Solution"
        }
    }
    
    func locationAsString() -> String {
        switch self.location! {
            case .CGMLocationFinger :
                return "Finger"
            case .CGMLocationAlternateSiteTest :
                return "Alternate site test"
            case .CGMLocationEarlobe :
                return "Earlobe"
            case .CGMLocationControlSolution :
                return "Control solution"
            case .CGMLocationSubcutaneousTissue :
                return "Subcutaneous tissue"
            case .CGMLocationValueNotAvailable :
                return "Location Not available"
        }
    }
}
