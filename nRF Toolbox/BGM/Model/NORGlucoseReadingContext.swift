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
    var sequenceNumber         : UInt16?
    var carbohydratePresent    : Bool?
    var carbohydrateId         : BgmCarbohydrateId?
    var carbohydrate           : Float32?
    var mealPresent            : Bool?
    var meal                   : BgmMeal?
    var testerAndHealthPresent : Bool?
    var tester                 : BgmTester?
    var health                 : BgmHealth?
    var exercisePresent        : Bool?
    var exerciseDuration       : UInt16?
    var exerciseIntensity      : UInt8?
    var medicationPresent      : Bool?
    var medicationId           : BgmMedicationId?
    var medication             : Float32?
    var medicationUnit         : BgmMedicationUnit?
    var HbA1cPresent           : Bool?
    var HbA1c                  : Float32?
 
    //MARK: - Enums
    enum BgmCarbohydrateId: UInt8 {
        case RESERVED_CARBOHYDRATE  = 0
        case BREAKFEST              = 1
        case LUNCH                  = 2
        case DINNER                 = 3
        case SNACK                  = 4
        case DRINK                  = 5
        case SUPPER                 = 6
        case BRUNCH                 = 7
    }
    
    enum BgmMeal : UInt8 {
        case RESERVED_MEAL  = 0
        case PREPRANDIAL    = 1
        case POSTPRANDIAL   = 2
        case FASTING        = 3
        case CASUAL         = 4
        case BEDTIME        = 5
    }
    
    enum BgmTester : UInt8 {
        case RESERVED_TESTER            = 0
        case SELF                       = 1
        case HEALTH_CARE_PROFESSIONAL   = 2
        case LAB_TEST                   = 3
        case TESTER_NOT_AVAILABLE       = 15
    }
    
    enum BgmHealth : UInt8 {
        case RESERVED_HEALTH        = 0
        case MINOR_HEALTH_ISSUES    = 1
        case MAJOR_HEALTH_ISSUES    = 2
        case DURING_MENSES          = 3
        case UNDER_STRESS           = 4
        case NO_HEALTH_ISSUES       = 5
        case HEALTH_NOT_AVAILABLE   = 15
    }
    
    enum BgmMedicationId : UInt8 {
        case RESERVED_MEDICATON             = 0
        case RAPID_ACTING_INSULIN           = 1
        case SHORT_ACTING_INSULIN           = 2
        case INTERMEDIATE_ACTING_INSULIN    = 3
        case LONG_ACTING_INSULINE           = 4
        case PRE_MIXED_INSULINE             = 5
    }
    
    enum BgmMedicationUnit : UInt8 {
        case KILOGRAMS  = 0
        case LITERS     = 1
    }
  
    //MARK: - Implementation
    static func readingContextFromBytes(bytes: UnsafePointer<UInt8>) -> NORGlucoseReadingContext {
        let context = NORGlucoseReadingContext()
        context.updateFromBytes(bytes)
        return context;
    }
    
    func updateFromBytes(bytes: UnsafePointer<UInt8>){
        var pointer = UnsafeMutablePointer<UInt8>(bytes)
        
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
        
        if (extendedFlags)
        {
            pointer = pointer.successor(); // skip Extended Flags, not supported
        }
        
        self.carbohydratePresent = carbohydrateIdPresent
        if (carbohydrateIdPresent)
        {
            self.carbohydrateId = BgmCarbohydrateId(rawValue:NORCharacteristicReader.readUInt8Value(ptr: &pointer))
            self.carbohydrate = NORCharacteristicReader.readSFloatValue(ptr: &pointer) / 1000
        }
        
        self.mealPresent = mealPresent
        if (mealPresent)
        {
            self.meal = BgmMeal(rawValue:NORCharacteristicReader.readUInt8Value(ptr: &pointer))
        }
        
        self.testerAndHealthPresent = testerAndHelathPresent
        if (testerAndHelathPresent)
        {
            let nibble = NORCharacteristicReader.readNibble(ptr: &pointer)
            self.tester = BgmTester(rawValue: nibble.first)
            self.health = BgmHealth(rawValue: nibble.second)
        }
        
        self.exercisePresent = exerciseInfoPresent
        if (exerciseInfoPresent)
        {
            self.exerciseDuration = NORCharacteristicReader.readUInt16Value(ptr: &pointer)
            self.exerciseIntensity = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
        }
        
        self.medicationPresent = medicationPresent
        if (medicationPresent)
        {
            self.medicationId = BgmMedicationId(rawValue:NORCharacteristicReader.readUInt8Value(ptr: &pointer));
            self.medication = NORCharacteristicReader.readSFloatValue(ptr: &pointer) / 1000000
            self.medicationUnit = medicationUnit
        }
        
        self.HbA1cPresent = HbA1cPresent
        if (HbA1cPresent)
        {
            self.HbA1c = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
        }
    }

    func carbohydrateIdAsString() -> String {
        switch(self.carbohydrateId!){
        case .BREAKFEST:
            return "Breakfast"
        case .BRUNCH:
            return "Brunch"
        case .DINNER:
            return "Dinner"
        case .DRINK:
            return "Drink"
        case .LUNCH:
            return "Lunch"
        case .SNACK:
            return "Snack"
        case .SUPPER:
            return "Supper"
        default:
            return String(format: "Reserved: %d", (self.carbohydrateId?.rawValue)!)
        }
    }
    
    func mealIdAsString() -> String {
        switch (self.meal!) {
        case .BEDTIME:
            return "Bedtime"
        case .CASUAL:
            return "Casual"
        case .FASTING:
            return "Fasting"
        case .POSTPRANDIAL:
            return "Postprandial"
        case .PREPRANDIAL:
            return "Preprandial"
        default:
            return String(format:"Reserved: %d", (self.meal?.rawValue)!)
        }
    }
    
    func testerAsString() -> String {
        switch (self.tester!) {
        case .HEALTH_CARE_PROFESSIONAL:
            return "Healthcare professional"
        case .LAB_TEST:
            return "Lab test"
        case .SELF:
            return "Self"
        case .TESTER_NOT_AVAILABLE:
            return "Not available"
        default:
            return String(format:"Reserved: %d", (self.tester?.rawValue)!)
        }
    }
    
    func healthAsString() -> String {
        switch (self.health!) {
        case .DURING_MENSES:
            return "During menses"
        case .MINOR_HEALTH_ISSUES:
            return "Minor health issue"
        case .MAJOR_HEALTH_ISSUES:
            return "Major health issue"
        case .UNDER_STRESS:
            return "Under stress"
        case .NO_HEALTH_ISSUES:
            return "No health issues"
        case .HEALTH_NOT_AVAILABLE:
            return "Not availabel"
        default:
            return String(format:"RESERVED: %d", (self.health?.rawValue)!)
        }
    }
    
    func medicationIdAsString() -> String {
        switch (self.medicationId!) {
        case .INTERMEDIATE_ACTING_INSULIN:
            return "Intermediate acting insulin"
        case .LONG_ACTING_INSULINE:
            return "Long acting insulin"
        case .PRE_MIXED_INSULINE:
            return "Pre-mixed insulin"
        case .RAPID_ACTING_INSULIN:
            return "Rapid acting insulin"
        case .SHORT_ACTING_INSULIN:
            return "Short acting insulin"
        default:
            return String(format:"Reserved: %d", (self.medicationId?.rawValue)!)
        }
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        let reading = object as! NORGlucoseReadingContext
        return self.sequenceNumber == reading.sequenceNumber!
    }
}
