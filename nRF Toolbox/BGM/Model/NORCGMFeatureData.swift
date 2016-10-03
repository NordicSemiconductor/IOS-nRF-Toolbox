//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum CGMFeatureFlags : UInt8 {
    case cgmFeatureCalibrationSupport                       = 0
    case cgmFeaturePatientHighLowAlertsSupport              = 1
    case cgmFeatureHypoAlertsSupport                        = 2
    case cgmFeatureHyperAlertsSupport                       = 3
    case cgmFeatureRateofIncreaseDecreaseAlertsSupport      = 4
    case cgmFeatureDeviceSpecificAlertSupport               = 5
    case cgmFeatureSensorMalfunctionDetectionSupport        = 6
    case cgmFeatureSensorTemperatureHighLowDetectionSupport = 7
    case cgmFeatureSensorResultHighLowDetectionSupport      = 8
    case cgmFeatureLowBatteryDetectionSupport               = 9
    case cgmFeatureSensorTypeErrorDetectionSupport          = 10
    case cgmFeatureGeneralDeviceFaultSupport                = 11
    case cgmFeatureE2ECRCSupport                            = 12
    case cgmFeatureMultipleBondSupport                      = 13
    case cgmFeatureMultipleSessionsSupport                  = 14
    case cgmFeatureCGMTrendInformationSupport               = 15
    case cgmFeatureCGMQualitySupport                        = 16
}

enum CGMType : UInt8 {
    case cgmTypeCapillaryWholeBlood    = 1
    case cgmTypeCapillaryPlasma        = 2
    case cgmTypeCapillaryWholeBlood2   = 3
    case cgmTypeVenousPlasma           = 4
    case cgmTypeArterialWholeBlood     = 5
    case cgmTypeArterialPlasma         = 6
    case cgmTypeUndeterminedWholeBlood = 7
    case cgmTypeUndeterminedPlasma     = 8
    case cgmTypeInterstitialFluid      = 9
    case cgmTypeControlSolution        = 10
}

enum CGMLocation : UInt8{
    case cgmLocationFinger             = 1
    case cgmLocationAlternateSiteTest  = 2
    case cgmLocationEarlobe            = 3
    case cgmLocationControlSolution    = 4
    case cgmLocationSubcutaneousTissue = 5
    case cgmLocationValueNotAvailable  = 15
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
    
    func updateFromBytes(_ bytes : UnsafeMutablePointer<UInt8>) {

        var pointer = bytes
        pointer += 3 //Skip flags

        let typeAndLocation = NORCharacteristicReader.readNibble(ptr: &pointer)
        self.type = CGMType(rawValue: typeAndLocation.second)!
        self.location = CGMLocation(rawValue: typeAndLocation.first)!

    }

    func typeAsString() -> String {
        switch self.type! {
        case .cgmTypeCapillaryWholeBlood:
            return "Capillay whole blood"
            
        case .cgmTypeCapillaryPlasma:
            return "Capillary Plasma"
            
        case .cgmTypeCapillaryWholeBlood2:
            return "Capillary whole blood"
            
        case .cgmTypeVenousPlasma:
            return "Venous plasma"
            
        case .cgmTypeArterialWholeBlood:
            return "Arterial whole blood"
            
        case .cgmTypeArterialPlasma:
            return "Arterial Plasma"
            
        case .cgmTypeUndeterminedWholeBlood:
            return "Undetermined whole blood"
            
        case .cgmTypeUndeterminedPlasma:
            return "Underetmined plasma"
            
        case .cgmTypeInterstitialFluid:
            return "Interstitial fluid"
            
        case .cgmTypeControlSolution:
            return "Control Solution"
        }
    }
    
    func locationAsString() -> String {
        switch self.location! {
            case .cgmLocationFinger :
                return "Finger"
            case .cgmLocationAlternateSiteTest :
                return "Alternate site test"
            case .cgmLocationEarlobe :
                return "Earlobe"
            case .cgmLocationControlSolution :
                return "Control solution"
            case .cgmLocationSubcutaneousTissue :
                return "Subcutaneous tissue"
            case .cgmLocationValueNotAvailable :
                return "Location Not available"
        }
    }
}
