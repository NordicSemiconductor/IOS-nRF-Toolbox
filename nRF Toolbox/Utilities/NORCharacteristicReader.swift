//
//  NORCharacteristicReader.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 18/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct NORNibble {
    var first  : UInt8
    var second : UInt8
}


enum NORReservedSFloatValues : Int16 {
    case MDER_S_POSITIVE_INFINITY = 0x07FE
    case MDER_S_NaN = 0x07FF
    case MDER_S_NRes = 0x0800
    case MDER_S_RESERVED_VALUE = 0x0801
    case MDER_S_NEGATIVE_INFINITY = 0x0802
}

enum NORReservedFloatValues : UInt32 {
    case MDER_POSITIVE_INFINITY = 0x007FFFFE
    case MDER_NaN = 0x007FFFFF
    case MDER_NRes = 0x00800000
    case MDER_RESERVED_VALUE = 0x00800001
    case MDER_NEGATIVE_INFINITY = 0x00800002
}

let FIRST_S_RESERVED_VALUE = NORReservedSFloatValues.MDER_S_POSITIVE_INFINITY
let FIRST_RESERVED_VALUE   = NORReservedFloatValues.MDER_POSITIVE_INFINITY
let RESERVED_FLOAT_VALUES : Array<Double> = [Double.infinity, Double.NaN,Double.NaN,Double.NaN, -Double.infinity]

struct NORCharacteristicReader {

    static func readUInt8Value(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> UInt8 {
        let val = aPointer.memory
        aPointer = aPointer.successor()
        return val
    }
    
    static func readSInt8Value(ptr aPointer : UnsafeMutablePointer<UInt8>) -> Int8 {
        return Int8(aPointer.successor().memory)
    }

    static func readUInt16Value(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> UInt16 {
        let anUInt16Pointer = UnsafeMutablePointer<UInt16>(aPointer)
        let val = CFSwapInt16LittleToHost(anUInt16Pointer.memory)
        aPointer = aPointer.advancedBy(2)
        return val
    }
    
    static func readSInt16Value(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> Int16 {
        let anInt16Pointer = UnsafeMutablePointer<Int16>(aPointer)
        let val = CFSwapInt16LittleToHost(UnsafeMutablePointer<UInt16>(anInt16Pointer).memory)
        aPointer = aPointer.advancedBy(2)
        return Int16(val)
    }
    
    static func readUInt32Value(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> UInt32 {
        let anInt32Pointer = UnsafeMutablePointer<UInt32>(aPointer)
        let val = CFSwapInt32LittleToHost(UnsafeMutablePointer<UInt32>(anInt32Pointer).memory)
        aPointer = aPointer.advancedBy(4)
        return UInt32(val)
    }
    
    static func readSInt32Value(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> Int32 {
        let anInt32Pointer = UnsafeMutablePointer<UInt32>(aPointer)
        let val  = CFSwapInt32LittleToHost(UnsafeMutablePointer<UInt32>(anInt32Pointer).memory)
        aPointer = aPointer.advancedBy(4)
        return Int32(val)
    }
    
    static func readSFloatValue(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> Float32 {
        let tempData = CFSwapInt16LittleToHost(UnsafeMutablePointer<UInt16>(aPointer).memory)
        var mantissa = Int16(tempData & 0x0FFF)
        var exponent = Int8(tempData >> 12)
        if exponent >= 0x0008 {
            exponent = -((0x000F + 1) - exponent)
        }

        var output : Float32 = 0
        
        if mantissa >= FIRST_S_RESERVED_VALUE.rawValue && mantissa <= NORReservedSFloatValues.MDER_S_NEGATIVE_INFINITY.rawValue {
            output = Float32(RESERVED_FLOAT_VALUES[mantissa - FIRST_S_RESERVED_VALUE.rawValue])
        }else{
            if mantissa > 0x0800 {
                mantissa = -((0x0FFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        aPointer = aPointer.advancedBy(2)
        
        return output
    }
    
    static func readFloatValue(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> Float32 {
        let tempData = CFSwapInt32LittleToHost(UInt32(aPointer.memory))
        var mantissa = Int32(tempData & 0xFFFFff)
        let exponent = Int8(tempData >> 24)
        
        var output : Float32 = 0
        
        if mantissa >= Int32(FIRST_RESERVED_VALUE.rawValue) && mantissa <= Int32(NORReservedFloatValues.MDER_NEGATIVE_INFINITY.rawValue) {
            output = Float32(RESERVED_FLOAT_VALUES[mantissa - Int32(FIRST_S_RESERVED_VALUE.rawValue)])
        }else{
            if mantissa >= 0x800000 {
                mantissa = -((0xFFFFFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        
        aPointer = aPointer.advancedBy(4)
        return output
    }
    
    static func readDateTime(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> NSDate {
        let year  = NORCharacteristicReader.readUInt16Value(ptr: &aPointer)
        let month = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let day   = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let hour  = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let min   = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let sec   = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        
        let dateString = String(format: "%d %d %d %d %d %d", year, month, day, hour, min, sec)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
        return dateFormatter.dateFromString(dateString)!
    }
    
    static func readNibble(inout ptr aPointer : UnsafeMutablePointer<UInt8>) -> NORNibble {
        let value = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let nibble = NORNibble(first: value & 0xF, second: value >> 4)
        return nibble
    }
}