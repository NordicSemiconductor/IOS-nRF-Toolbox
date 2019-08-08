//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORGlucoseReading: NSObject {

    //MARK: - Properties
    var sequenceNumber                              : UInt16
    var timestamp                                   : Date
    var timeOffset                                  : Int16?
    var glucoseConcentrationTypeAndLocationPresent  : Bool
    var glucoseConcentration                        : Float32?
    var unit                                        : BGMUnit?
    var type                                        : BGMType?
    var location                                    : BGMLocation?
    var sensorStatusAnnunciationPresent             : Bool
    var sensorStatusAnnunciation                    : UInt16?
    var context                                     : NORGlucoseReadingContext?

    //MARK: - Enum Definitions
    enum BGMUnit : UInt8 {
        case kg_L                    = 0
        case mol_L                   = 1
    }
    
    enum BGMType : UInt8{
        case reserved                = 0
        case capillaryWholeBlood     = 1
        case capillaryPlasma         = 2
        case venousWholeBlood        = 3
        case venousPlasma            = 4
        case arterialWholeBlood      = 5
        case arterialPlasma          = 6
        case undeterminedWholeBlood  = 7
        case undeterminedPlasma      = 8
        case interstitialFluid       = 9
        case controlSolution         = 10
    }

    enum BGMLocation : UInt8 {
        case reserved          = 0
        case finger            = 1
        case alternateSiteTest = 2
        case earlobe           = 3
        case controlSolution   = 4
        case notAvailable      = 15
    }

    //MARK: - Implementation
    
    init(_ bytes : UnsafePointer<UInt8>) {
        var pointer = UnsafeMutablePointer<UInt8>(mutating: bytes)
        
        //Parse falgs
        let flags = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
        let timeOffsetPresent: Bool = (flags & 0x01) > 0
        let glucoseConcentrationTypeAndLocationPresent: Bool = (flags & 0x02) > 0
        let glucoseConcentrationUnit = BGMUnit(rawValue: (flags & 0x04) >> 2)
        let statusAnnuciationPresent :Bool = (flags & 0x08) > 0
        
        // Sequence number is used to match the reading with an optional glucose context
        self.sequenceNumber = NORCharacteristicReader.readUInt16Value(ptr: &pointer)
        self.timestamp      = NORCharacteristicReader.readDateTime(ptr: &pointer)
        
        if timeOffsetPresent {
            timeOffset = NORCharacteristicReader.readSInt16Value(ptr: &pointer)
            timestamp.addTimeInterval(Double(timeOffset!) * 60.0)
        }
        
        self.glucoseConcentrationTypeAndLocationPresent = glucoseConcentrationTypeAndLocationPresent
        if self.glucoseConcentrationTypeAndLocationPresent == true {
            self.glucoseConcentration = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
            self.unit = glucoseConcentrationUnit
            let typeAndLocation = NORCharacteristicReader.readNibble(ptr: &pointer)
            self.type       = BGMType(rawValue: typeAndLocation.first) ?? .reserved
            self.location   = BGMLocation(rawValue: typeAndLocation.second) ?? .notAvailable
        } else {
            self.type       = BGMType.reserved
            self.location   = BGMLocation.notAvailable
        }

        self.sensorStatusAnnunciationPresent = statusAnnuciationPresent
        if statusAnnuciationPresent {
            self.sensorStatusAnnunciation = NORCharacteristicReader.readUInt16Value(ptr: &pointer)
        }
    }
    
    //MARK: - Static methods
    static func readingFromBytes(_ bytes: UnsafePointer<UInt8>) -> NORGlucoseReading {
        return NORGlucoseReading(bytes)
    }
}

extension NORGlucoseReading.BGMLocation: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .alternateSiteTest:
            return "Alternate site test"
        case .controlSolution:
            return "Control solution"
        case .earlobe:
            return "Earlobe"
        case .finger:
            return "Finger"
        case .notAvailable:
            return "Not available"
        case .reserved:
            return "Reserved value"
        }
    }
    
}

extension NORGlucoseReading.BGMType: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .arterialPlasma:
            return "Arterial plasma"
        case .arterialWholeBlood:
            return "Arterial whole blood"
        case .capillaryPlasma:
            return "Capillary plasma"
        case .capillaryWholeBlood:
            return "Capillary whole blood"
        case .controlSolution:
            return "Control solution"
        case .interstitialFluid:
            return "Interstitial fluid (ISF)"
        case .undeterminedPlasma:
            return "Undetermined plasma"
        case .undeterminedWholeBlood:
            return "Undetermined whole blood"
        case .venousPlasma:
            return "Venous plasma"
        case .venousWholeBlood:
            return "Venous whole blood"
        case .reserved:
            return "Reserved value"
        }
    }
    
}
