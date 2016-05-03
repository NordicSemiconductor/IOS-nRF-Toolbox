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
    var timestamp                                   : NSDate?
    var timeOffset                                  : Int16?
    var glucoseConcentrationTypeAndLocationPresent  : Bool?
    var glucoseConcentration                        : Float32?
    var unit                                        : BGMUnit?
    var type                                        : BGMType?
    var location                                    : BGMLocation?
    var sensorStatusAnnunciationPresent             : Bool?
    var sensorStatusAnnunciation                    : UInt16?
    var context                                     : GlucoseReadingContext?

    //MARK: - Enum Definitions
    enum BGMUnit : UInt8 {
        case KG_L                       = 0
        case MOL_L                      = 1
    }
    
    enum BGMType : UInt8{
        case RESERVED_TYPE              = 0
        case CAPILLARY_WHOLE_BLOOD      = 1
        case CAPILLARY_PLASMA           = 2
        case VENOUS_WHOLE_BLOOD         = 3
        case VENOUS_PLASMA              = 4
        case ARTERIAL_WHOLE_BLOOD       = 5
        case ARTERIAL_PLASMA            = 6
        case UNDETERMINED_WHOLE_BLOOD   = 7
        case UNDETERMINED_PLASMA        = 8
        case INTERSTITIAL_FLUID         = 9
        case CONTROL_SOLUTION_TYPE      = 10
    }

    enum BGMLocation : UInt8 {
        case RESERVED_LOCATION          = 0
        case FINGER                     = 1
        case ALTERNATE_SITE_TEST        = 2
        case EARLOBE                    = 3
        case CONTROL_SOLUTION_LOCATION  = 4
        case LOCATION_NOT_AVAILABLE     = 15
    }


    //MARK: - Implementation
    //TODO: Remove me, this is a quick fix to help with Swift->Objc bridging
    func sequneceNumber() -> UInt16 {
        return self.sequenceNumber!
    }

    func locationAsString() -> String {
        return "Lcoation"
    }
    
    func typeAsString() -> String {
        return "Type"
    }
    
    func updateFromBytes(bytes : UnsafePointer<UInt8>) {
        
        var pointer = UnsafeMutablePointer<UInt8>(bytes)
        
        //Parse falgs
        let flags = CharacteristicReader.readUInt8Value(&pointer)
        let timeOffsetPresent: Bool = (flags & 0x01) > 0
        let glucoseConcentrationTypeAndLocationPresent: Bool = (flags & 0x02) > 0
        let glucoseConcentrationUnit = BGMUnit(rawValue: (flags & 0x04) >> 2)
        let statusAnnuciationPresent :Bool = (flags & 0x08) > 0
        
        // Sequence number is used to match the reading with an optional glucose context
        self.sequenceNumber = CharacteristicReader.readUInt16Value(&pointer)
        self.timestamp      = CharacteristicReader.readDateTime(&pointer)
        
        if timeOffsetPresent {
            self.timeOffset = CharacteristicReader.readSInt16Value(&pointer)
        }
        
        self.glucoseConcentrationTypeAndLocationPresent = glucoseConcentrationTypeAndLocationPresent
        self.unit = glucoseConcentrationUnit
        
        let typeAndLocation : Nibble = CharacteristicReader.readNibble(&pointer)
        self.type       = BGMType(rawValue: typeAndLocation.parts.first)
        self.location   = BGMLocation(rawValue: typeAndLocation.parts.second)
        
        self.sensorStatusAnnunciationPresent = statusAnnuciationPresent
        if statusAnnuciationPresent == true {
            self.sensorStatusAnnunciation = CharacteristicReader.readUInt16Value(&pointer)
        }
    }
    
    //MARK: - Static methods
    static func readingFromBytes(bytes: UnsafePointer<UInt8>) -> NORGlucoseReading {
        let aReading = NORGlucoseReading()
        aReading.updateFromBytes(bytes)
        return aReading
    }
}
