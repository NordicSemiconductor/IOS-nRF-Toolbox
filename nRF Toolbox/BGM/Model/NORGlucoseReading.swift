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
    var sequenceNumber                              : UInt16?
    var timestamp                                   : Date?
    var timeOffset                                  : Int16?
    var glucoseConcentrationTypeAndLocationPresent  : Bool?
    var glucoseConcentration                        : Float32?
    var unit                                        : BGMUnit?
    var type                                        : BGMType?
    var location                                    : BGMLocation?
    var sensorStatusAnnunciationPresent             : Bool?
    var sensorStatusAnnunciation                    : UInt16?
    var context                                     : NORGlucoseReadingContext?

    //MARK: - Enum Definitions
    enum BGMUnit : UInt8 {
        case kg_L                       = 0
        case mol_L                      = 1
    }
    
    enum BGMType : UInt8{
        case reserved_TYPE              = 0
        case capillary_WHOLE_BLOOD      = 1
        case capillary_PLASMA           = 2
        case venous_WHOLE_BLOOD         = 3
        case venous_PLASMA              = 4
        case arterial_WHOLE_BLOOD       = 5
        case arterial_PLASMA            = 6
        case undetermined_WHOLE_BLOOD   = 7
        case undetermined_PLASMA        = 8
        case interstitial_FLUID         = 9
        case control_SOLUTION_TYPE      = 10
    }

    enum BGMLocation : UInt8 {
        case reserved_LOCATION          = 0
        case finger                     = 1
        case alternate_SITE_TEST        = 2
        case earlobe                    = 3
        case control_SOLUTION_LOCATION  = 4
        case location_NOT_AVAILABLE     = 15
    }


    //MARK: - Implementation
    //TODO: Remove me, this is a quick fix to help with Swift->Objc bridging
    func sequneceNumber() -> UInt16 {
        return self.sequenceNumber!
    }

    func locationAsString() -> String {
        switch self.location! {
        case .alternate_SITE_TEST:
            return "Alternate site test"
        case .control_SOLUTION_LOCATION:
            return "Control solution"
        case .earlobe:
            return "Earlobe"
        case .finger:
            return "Finger"
        case .location_NOT_AVAILABLE:
            return "Not available"
        case .reserved_LOCATION:
            return "Reserved value"
        }
    }
    
    func typeAsString() -> String {
        switch self.type!{
        case .arterial_PLASMA:
            return "Arterial plasma"
        case .arterial_WHOLE_BLOOD:
            return "Arterial whole blood"
        case .capillary_PLASMA:
            return "Capillary plasma"
        case .capillary_WHOLE_BLOOD:
            return "Capillary whole blood"
        case .control_SOLUTION_TYPE:
            return "Control solution"
        case .interstitial_FLUID:
            return "Interstitial fluid"
        case .undetermined_PLASMA:
            return "Undetermined plasma"
        case .undetermined_WHOLE_BLOOD:
            return "Undetermined whole blood"
        case .venous_PLASMA:
            return "Venous plasma"
        case .venous_WHOLE_BLOOD:
            return "Venous whole blood"
        case .reserved_TYPE:
            return "Reserved value"
        }
    }
    
    func updateFromBytes(_ bytes : UnsafePointer<UInt8>) {
        
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
            self.timeOffset = NORCharacteristicReader.readSInt16Value(ptr: &pointer)
        }
        
        self.glucoseConcentrationTypeAndLocationPresent = glucoseConcentrationTypeAndLocationPresent
        if self.glucoseConcentrationTypeAndLocationPresent == true {
            self.glucoseConcentration = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
            self.unit = glucoseConcentrationUnit
            let typeAndLocation = NORCharacteristicReader.readNibble(ptr: &pointer)
            self.type       = BGMType(rawValue: typeAndLocation.first)
            self.location   = BGMLocation(rawValue: typeAndLocation.second)
        } else {
            self.type       = BGMType.reserved_TYPE
            self.location   = BGMLocation.reserved_LOCATION
        }

        self.sensorStatusAnnunciationPresent = statusAnnuciationPresent
        if statusAnnuciationPresent == true {
            self.sensorStatusAnnunciation = NORCharacteristicReader.readUInt16Value(ptr: &pointer)
        }
    }
    
    //MARK: - Static methods
    static func readingFromBytes(_ bytes: UnsafePointer<UInt8>) -> NORGlucoseReading {
        let aReading = NORGlucoseReading()
        aReading.updateFromBytes(bytes)
        return aReading
    }
}
