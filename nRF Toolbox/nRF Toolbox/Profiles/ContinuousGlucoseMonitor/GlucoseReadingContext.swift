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

struct GlucoseReadingContext {

    //MARK: - Properties
    let sequenceNumber         : UInt16
    let carbohydratePresent    : Bool
    let carbohydrateId         : BgmCarbohydrateId?
    let carbohydrate           : Float32?
    let mealPresent            : Bool
    let meal                   : BgmMeal?
    let testerAndHealthPresent : Bool
    let tester                 : BgmTester?
    let health                 : BgmHealth?
    let exercisePresent        : Bool
    let exerciseDuration       : UInt16?
    let exerciseIntensity      : UInt8?
    let medicationPresent      : Bool
    let medicationId           : BgmMedicationId?
    let medication             : Float32?
    let medicationUnit         : BgmMedicationUnit?
    let HbA1cPresent           : Bool
    let HbA1c                  : Float32?
 
    //MARK: - Enums
    enum BgmCarbohydrateId: UInt8 {
        case reserved  = 0
        case breakfest = 1
        case lunch     = 2
        case dinner    = 3
        case snack     = 4
        case drink     = 5
        case supper    = 6
        case brunch    = 7
    }
    
    enum BgmMeal : UInt8 {
        case reserved     = 0
        case preprandial  = 1
        case postprandial = 2
        case fasting      = 3
        case casual       = 4
        case bedtime      = 5
    }
    
    enum BgmTester : UInt8 {
        case reserved               = 0
        case `self`                 = 1
        case healthcareProfessional = 2
        case labTest                = 3
        case notAvailable           = 15
    }
    
    enum BgmHealth : UInt8 {
        case reserved          = 0
        case minorHealthIssues = 1
        case majorHealthIssues = 2
        case duringMenses      = 3
        case underStress       = 4
        case noHealthIssues    = 5
        case notAvailable      = 15
    }
    
    enum BgmMedicationId : UInt8 {
        case reserved                  = 0
        case rapidActingInsulin        = 1
        case shortActingInsulin        = 2
        case intermediateActingInsulin = 3
        case longActingInsulin         = 4
        case preMixedInsuline          = 5
    }
    
    enum BgmMedicationUnit : UInt8 {
        case kilograms  = 0
        case liters     = 1
    }
  
    //MARK: - Implementation
    init(_ bytes: UnsafePointer<UInt8>){
        var pointer = UnsafeMutablePointer<UInt8>(mutating: bytes)
        
        // Parse flags
        let flags = CharacteristicReader.readUInt8Value(ptr: &pointer)
        let carbohydrateIdPresent : Bool = (flags & 0x01) > 0
        let mealPresent : Bool = (flags & 0x02) > 0
        let testerAndHelathPresent : Bool = (flags & 0x04) > 0
        let exerciseInfoPresent : Bool = (flags & 0x08) > 0
        let medicationPresent : Bool = (flags & 0x10) > 0
        let medicationUnit = BgmMedicationUnit(rawValue: (flags & 0x20) >> 5)
        let HbA1cPresent : Bool = (flags & 0x40) > 0
        let extendedFlags : Bool = (flags & 0x80) > 0
        
        // Sequence number is used to match the reading with the glucose measurement
        self.sequenceNumber = CharacteristicReader.readUInt16Value(ptr: &pointer)
        
        if extendedFlags {
            pointer = pointer.successor(); // skip Extended Flags, not supported
        }
        
        self.carbohydratePresent = carbohydrateIdPresent
        if carbohydrateIdPresent {
            self.carbohydrateId = BgmCarbohydrateId(rawValue: CharacteristicReader.readUInt8Value(ptr: &pointer))
            self.carbohydrate = CharacteristicReader.readSFloatValue(ptr: &pointer) / 1000
        } else {
            self.carbohydrateId = nil
            self.carbohydrate = nil
        }
        
        self.mealPresent = mealPresent
        if mealPresent {
            self.meal = BgmMeal(rawValue:CharacteristicReader.readUInt8Value(ptr: &pointer))
        } else {
            self.meal = nil
        }
        
        self.testerAndHealthPresent = testerAndHelathPresent
        if testerAndHelathPresent {
            let nibble = CharacteristicReader.readNibble(ptr: &pointer)
            self.tester = BgmTester(rawValue: nibble.first)
            self.health = BgmHealth(rawValue: nibble.second)
        } else {
            self.tester = nil
            self.health = nil
        }
        
        self.exercisePresent = exerciseInfoPresent
        if exerciseInfoPresent {
            self.exerciseDuration = CharacteristicReader.readUInt16Value(ptr: &pointer)
            self.exerciseIntensity = CharacteristicReader.readUInt8Value(ptr: &pointer)
        } else {
            self.exerciseDuration = nil
            self.exerciseIntensity = nil
        }
        
        self.medicationPresent = medicationPresent
        if medicationPresent {
            self.medicationId = BgmMedicationId(rawValue:CharacteristicReader.readUInt8Value(ptr: &pointer));
            self.medication = CharacteristicReader.readSFloatValue(ptr: &pointer) / 1000000
            self.medicationUnit = medicationUnit
        } else {
            self.medicationId = nil
            self.medication = nil
            self.medicationUnit = nil
        }
        
        self.HbA1cPresent = HbA1cPresent
        if HbA1cPresent {
            self.HbA1c = CharacteristicReader.readSFloatValue(ptr: &pointer)
        } else {
            self.HbA1c = nil
        }
    }
    
}

extension GlucoseReadingContext: Equatable {
    
    static func == (lhs: GlucoseReadingContext, rhs: GlucoseReading) -> Bool {
        return lhs.sequenceNumber == rhs.sequenceNumber
    }
    
    static func == (lhs: GlucoseReadingContext, rhs: GlucoseReadingContext) -> Bool {
        return lhs.sequenceNumber == rhs.sequenceNumber
    }
    
}

extension GlucoseReadingContext.BgmCarbohydrateId: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .breakfest:
            return "Breakfast"
        case .brunch:
            return "Brunch"
        case .dinner:
            return "Dinner"
        case .drink:
            return "Drink"
        case .lunch:
            return "Lunch"
        case .snack:
            return "Snack"
        case .supper:
            return "Supper"
        default:
            return "Reserved"
        }
    }
}

extension GlucoseReadingContext.BgmMeal: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .bedtime:
            return "Bedtime"
        case .casual:
            return "Casual"
        case .fasting:
            return "Fasting"
        case .postprandial:
            return "Postprandial"
        case .preprandial:
            return "Preprandial"
        default:
            return "Reserved"
        }
    }
    
}

extension GlucoseReadingContext.BgmTester: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .healthcareProfessional:
            return "Healthcare professional"
        case .labTest:
            return "Lab test"
        case .`self`:
            return "Self"
        case .notAvailable:
            return "Not available"
        default:
            return "Reserved"
        }
    }
}

extension GlucoseReadingContext.BgmHealth: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .duringMenses:
            return "During menses"
        case .minorHealthIssues:
            return "Minor health issue"
        case .majorHealthIssues:
            return "Major health issue"
        case .underStress:
            return "Under stress"
        case .noHealthIssues:
            return "No health issues"
        case .notAvailable:
            return "Not available"
        default:
            return "Reserved"
        }
    }
}

extension GlucoseReadingContext.BgmMedicationId: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .intermediateActingInsulin:
            return "Intermediate acting insulin"
        case .longActingInsulin:
            return "Long acting insulin"
        case .preMixedInsuline:
            return "Pre-mixed insulin"
        case .rapidActingInsulin:
            return "Rapid acting insulin"
        case .shortActingInsulin:
            return "Short acting insulin"
        default:
            return "Reserved"
        }
    }
    
}
