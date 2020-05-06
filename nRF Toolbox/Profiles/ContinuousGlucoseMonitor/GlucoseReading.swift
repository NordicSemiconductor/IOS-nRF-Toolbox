/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit

struct GlucoseReading {

    //MARK: - Properties
    let sequenceNumber                              : UInt16
    let timestamp                                   : Date
    let timeOffset                                  : Int16?
    let glucoseConcentrationTypeAndLocationPresent  : Bool
    let glucoseConcentration                        : Float32?
    let unit                                        : BGMUnit?
    let type                                        : BGMType?
    let location                                    : BGMLocation?
    let sensorStatusAnnunciationPresent             : Bool
    let sensorStatusAnnunciation                    : UInt16?
    var context                                     : GlucoseReadingContext?

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
        let flags = CharacteristicReader.readUInt8Value(ptr: &pointer)
        let timeOffsetPresent: Bool = (flags & 0x01) > 0
        let glucoseConcentrationTypeAndLocationPresent: Bool = (flags & 0x02) > 0
        let glucoseConcentrationUnit = BGMUnit(rawValue: (flags & 0x04) >> 2)
        let statusAnnuciationPresent :Bool = (flags & 0x08) > 0
        
        // Sequence number is used to match the reading with an optional glucose context
        self.sequenceNumber = CharacteristicReader.readUInt16Value(ptr: &pointer)
        var timestamp = CharacteristicReader.readDateTime(ptr: &pointer)
        
        if timeOffsetPresent {
            timeOffset = CharacteristicReader.readSInt16Value(ptr: &pointer)
            timestamp.addTimeInterval(Double(timeOffset!) * 60.0)
        } else {
            timeOffset = nil
        }
        self.timestamp = timestamp
        
        self.glucoseConcentrationTypeAndLocationPresent = glucoseConcentrationTypeAndLocationPresent
        if self.glucoseConcentrationTypeAndLocationPresent == true {
            self.glucoseConcentration = CharacteristicReader.readSFloatValue(ptr: &pointer)
            self.unit = glucoseConcentrationUnit
            let typeAndLocation = CharacteristicReader.readNibble(ptr: &pointer)
            self.type       = BGMType(rawValue: typeAndLocation.first) ?? .reserved
            self.location   = BGMLocation(rawValue: typeAndLocation.second) ?? .notAvailable
        } else {
            self.glucoseConcentration = nil
            self.unit = nil
            self.type = nil
            self.location = nil
        }

        self.sensorStatusAnnunciationPresent = statusAnnuciationPresent
        if statusAnnuciationPresent {
            self.sensorStatusAnnunciation = CharacteristicReader.readUInt16Value(ptr: &pointer)
        } else {
            self.sensorStatusAnnunciation = nil
        }
    }
}

extension GlucoseReading: Equatable {
    
    static func == (lhs: GlucoseReading, rhs: GlucoseReading) -> Bool {
        return lhs.sequenceNumber == rhs.sequenceNumber
    }
    
}

extension GlucoseReading.BGMLocation: CustomStringConvertible {
    
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

extension GlucoseReading.BGMType: CustomStringConvertible {
    
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
