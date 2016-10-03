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
        case reserved_CARBOHYDRATE  = 0
        case breakfest              = 1
        case lunch                  = 2
        case dinner                 = 3
        case snack                  = 4
        case drink                  = 5
        case supper                 = 6
        case brunch                 = 7
    }
    
    enum BgmMeal : UInt8 {
        case reserved_MEAL  = 0
        case preprandial    = 1
        case postprandial   = 2
        case fasting        = 3
        case casual         = 4
        case bedtime        = 5
    }
    
    enum BgmTester : UInt8 {
        case reserved_TESTER            = 0
        case `self`                       = 1
        case health_CARE_PROFESSIONAL   = 2
        case lab_TEST                   = 3
        case tester_NOT_AVAILABLE       = 15
    }
    
    enum BgmHealth : UInt8 {
        case reserved_HEALTH        = 0
        case minor_HEALTH_ISSUES    = 1
        case major_HEALTH_ISSUES    = 2
        case during_MENSES          = 3
        case under_STRESS           = 4
        case no_HEALTH_ISSUES       = 5
        case health_NOT_AVAILABLE   = 15
    }
    
    enum BgmMedicationId : UInt8 {
        case reserved_MEDICATON             = 0
        case rapid_ACTING_INSULIN           = 1
        case short_ACTING_INSULIN           = 2
        case intermediate_ACTING_INSULIN    = 3
        case long_ACTING_INSULINE           = 4
        case pre_MIXED_INSULINE             = 5
    }
    
    enum BgmMedicationUnit : UInt8 {
        case kilograms  = 0
        case liters     = 1
    }
  
    //MARK: - Implementation
    static func readingContextFromBytes(_ bytes: UnsafePointer<UInt8>) -> NORGlucoseReadingContext {
        let context = NORGlucoseReadingContext()
        context.updateFromBytes(bytes)
        return context;
    }
    
    func updateFromBytes(_ bytes: UnsafePointer<UInt8>){
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
            return String(format: "Reserved: %d", (self.carbohydrateId?.rawValue)!)
        }
    }
    
    func mealIdAsString() -> String {
        switch (self.meal!) {
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
            return String(format:"Reserved: %d", (self.meal?.rawValue)!)
        }
    }
    
    func testerAsString() -> String {
        switch (self.tester!) {
        case .health_CARE_PROFESSIONAL:
            return "Healthcare professional"
        case .lab_TEST:
            return "Lab test"
        case .`self`:
            return "Self"
        case .tester_NOT_AVAILABLE:
            return "Not available"
        default:
            return String(format:"Reserved: %d", (self.tester?.rawValue)!)
        }
    }
    
    func healthAsString() -> String {
        switch (self.health!) {
        case .during_MENSES:
            return "During menses"
        case .minor_HEALTH_ISSUES:
            return "Minor health issue"
        case .major_HEALTH_ISSUES:
            return "Major health issue"
        case .under_STRESS:
            return "Under stress"
        case .no_HEALTH_ISSUES:
            return "No health issues"
        case .health_NOT_AVAILABLE:
            return "Not availabel"
        default:
            return String(format:"RESERVED: %d", (self.health?.rawValue)!)
        }
    }
    
    func medicationIdAsString() -> String {
        switch (self.medicationId!) {
        case .intermediate_ACTING_INSULIN:
            return "Intermediate acting insulin"
        case .long_ACTING_INSULINE:
            return "Long acting insulin"
        case .pre_MIXED_INSULINE:
            return "Pre-mixed insulin"
        case .rapid_ACTING_INSULIN:
            return "Rapid acting insulin"
        case .short_ACTING_INSULIN:
            return "Short acting insulin"
        default:
            return String(format:"Reserved: %d", (self.medicationId?.rawValue)!)
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        let reading = object as! NORGlucoseReadingContext
        return self.sequenceNumber == reading.sequenceNumber!
    }
}
