//
//  NORGlucoseReadingContext.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORGlucoseReadingContext: NSObject {

    //MARK: - Properties
    var sequenceNumber         : UInt16
    var carbohydratePresent    : Bool
    var carbohydrateId         : BgmCarbohydrateId?
    var carbohydrate           : Float32?
    var mealPresent            : Bool
    var meal                   : BgmMeal?
    var testerAndHealthPresent : Bool
    var tester                 : BgmTester?
    var health                 : BgmHealth?
    var exercisePresent        : Bool
    var exerciseDuration       : UInt16?
    var exerciseIntensity      : UInt8?
    var medicationPresent      : Bool
    var medicationId           : BgmMedicationId?
    var medication             : Float32?
    var medicationUnit         : BgmMedicationUnit?
    var HbA1cPresent           : Bool
    var HbA1c                  : Float32?
 
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
    static func readingContextFromBytes(_ bytes: UnsafePointer<UInt8>) -> NORGlucoseReadingContext {
        return NORGlucoseReadingContext(bytes)
    }
    
    init(_ bytes: UnsafePointer<UInt8>){
        var pointer = UnsafeMutablePointer<UInt8>(mutating: bytes)
        
        // Parse flags
        let flags = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
        let carbohydrateIdPresent : Bool = (flags & 0x01) > 0
        let mealPresent : Bool = (flags & 0x02) > 0
        let testerAndHelathPresent : Bool = (flags & 0x04) > 0
        let exerciseInfoPresent : Bool = (flags & 0x08) > 0
        let medicationPresent : Bool = (flags & 0x10) > 0
        let medicationUnit = BgmMedicationUnit(rawValue: (flags & 0x20) >> 5)
        let HbA1cPresent : Bool = (flags & 0x40) > 0
        let extendedFlags : Bool = (flags & 0x80) > 0
        
        // Sequence number is used to match the reading with the glucose measurement
        self.sequenceNumber = NORCharacteristicReader.readUInt16Value(ptr: &pointer)
        
        if extendedFlags {
            pointer = pointer.successor(); // skip Extended Flags, not supported
        }
        
        self.carbohydratePresent = carbohydrateIdPresent
        if carbohydrateIdPresent {
            self.carbohydrateId = BgmCarbohydrateId(rawValue: NORCharacteristicReader.readUInt8Value(ptr: &pointer))
            self.carbohydrate = NORCharacteristicReader.readSFloatValue(ptr: &pointer) / 1000
        }
        
        self.mealPresent = mealPresent
        if mealPresent {
            self.meal = BgmMeal(rawValue:NORCharacteristicReader.readUInt8Value(ptr: &pointer))
        }
        
        self.testerAndHealthPresent = testerAndHelathPresent
        if testerAndHelathPresent {
            let nibble = NORCharacteristicReader.readNibble(ptr: &pointer)
            self.tester = BgmTester(rawValue: nibble.first)
            self.health = BgmHealth(rawValue: nibble.second)
        }
        
        self.exercisePresent = exerciseInfoPresent
        if exerciseInfoPresent {
            self.exerciseDuration = NORCharacteristicReader.readUInt16Value(ptr: &pointer)
            self.exerciseIntensity = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
        }
        
        self.medicationPresent = medicationPresent
        if medicationPresent {
            self.medicationId = BgmMedicationId(rawValue:NORCharacteristicReader.readUInt8Value(ptr: &pointer));
            self.medication = NORCharacteristicReader.readSFloatValue(ptr: &pointer) / 1000000
            self.medicationUnit = medicationUnit
        }
        
        self.HbA1cPresent = HbA1cPresent
        if HbA1cPresent {
            self.HbA1c = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        switch object {
        case let reading as NORGlucoseReading:
            return sequenceNumber == reading.sequenceNumber
        case let context as NORGlucoseReadingContext:
            return sequenceNumber == context.sequenceNumber
        default:
            return false
        }
    }
}



extension NORGlucoseReadingContext.BgmCarbohydrateId: CustomStringConvertible {
    
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

extension NORGlucoseReadingContext.BgmMeal: CustomStringConvertible {
    
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

extension NORGlucoseReadingContext.BgmTester: CustomStringConvertible {
    
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

extension NORGlucoseReadingContext.BgmHealth: CustomStringConvertible {
    
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

extension NORGlucoseReadingContext.BgmMedicationId: CustomStringConvertible {
    
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
