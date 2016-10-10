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
    case mder_S_POSITIVE_INFINITY = 0x07FE
    case mder_S_NaN = 0x07FF
    case mder_S_NRes = 0x0800
    case mder_S_RESERVED_VALUE = 0x0801
    case mder_S_NEGATIVE_INFINITY = 0x0802
}

enum NORReservedFloatValues : UInt32 {
    case mder_POSITIVE_INFINITY = 0x007FFFFE
    case mder_NaN = 0x007FFFFF
    case mder_NRes = 0x00800000
    case mder_RESERVED_VALUE = 0x00800001
    case mder_NEGATIVE_INFINITY = 0x00800002
}

let FIRST_S_RESERVED_VALUE = NORReservedSFloatValues.mder_S_POSITIVE_INFINITY
let FIRST_RESERVED_VALUE   = NORReservedFloatValues.mder_POSITIVE_INFINITY
let RESERVED_FLOAT_VALUES : Array<Double> = [Double.infinity, Double.nan,Double.nan,Double.nan, -Double.infinity]

struct NORCharacteristicReader {

    static func readUInt8Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt8 {
        let val = aPointer.pointee
        aPointer = aPointer.successor()
        return val
    }
    
    static func readSInt8Value(ptr aPointer : UnsafeMutablePointer<UInt8>) -> Int8 {
        return Int8(aPointer.successor().pointee)
    }

    static func readUInt16Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt16 {
        let anUInt16Pointer = UnsafeMutablePointer<UInt16>(OpaquePointer(aPointer))
        let val = CFSwapInt16LittleToHost(anUInt16Pointer.pointee)
        aPointer = aPointer.advanced(by: 2)
        return val
    }
    
    static func readSInt16Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Int16 {
        let anInt16Pointer = UnsafeMutablePointer<Int16>(OpaquePointer(aPointer))
        let val = CFSwapInt16LittleToHost(UnsafeMutablePointer<UInt16>(OpaquePointer(anInt16Pointer)).pointee)
        aPointer = aPointer.advanced(by: 2)
        return Int16(val)
    }
    
    static func readUInt32Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt32 {
        let anInt32Pointer = UnsafeMutablePointer<UInt32>(OpaquePointer(aPointer))
        let val = CFSwapInt32LittleToHost(UnsafeMutablePointer<UInt32>(OpaquePointer(anInt32Pointer)).pointee)
        aPointer = aPointer.advanced(by: 4)
        return UInt32(val)
    }
    
    static func readSInt32Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Int32 {
        let anInt32Pointer = UnsafeMutablePointer<UInt32>(OpaquePointer(aPointer))
        let val  = CFSwapInt32LittleToHost(UnsafeMutablePointer<UInt32>(OpaquePointer(anInt32Pointer)).pointee)
        aPointer = aPointer.advanced(by: 4)
        return Int32(val)
    }
    
    static func readSFloatValue(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Float32 {
        let tempData = CFSwapInt16LittleToHost(UnsafeMutablePointer<UInt16>(OpaquePointer(aPointer)).pointee)
        var mantissa = Int16(tempData & 0x0FFF)
        var exponent = Int8(tempData >> 12)
        if exponent >= 0x0008 {
            exponent = -((0x000F + 1) - exponent)
        }

        var output : Float32 = 0
        
        if mantissa >= FIRST_S_RESERVED_VALUE.rawValue && mantissa <= NORReservedSFloatValues.mder_S_NEGATIVE_INFINITY.rawValue {
            output = Float32(RESERVED_FLOAT_VALUES[mantissa - FIRST_S_RESERVED_VALUE.rawValue])
        }else{
            if mantissa > 0x0800 {
                mantissa = -((0x0FFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        aPointer = aPointer.advanced(by: 2)
        
        return output
    }
    
    static func readFloatValue(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Float32 {
        let tempData = CFSwapInt32LittleToHost(UnsafeMutablePointer<UInt32>(OpaquePointer(aPointer)).pointee)
        var mantissa = Int32(tempData & 0x00FFFFFF)
        let exponent = unsafeBitCast(UInt8(tempData >> 24), to: Int8.self)
        
        var output : Float32 = 0
        
        if mantissa >= Int32(FIRST_RESERVED_VALUE.rawValue) && mantissa <= Int32(NORReservedFloatValues.mder_NEGATIVE_INFINITY.rawValue) {
            output = Float32(RESERVED_FLOAT_VALUES[mantissa - Int32(FIRST_S_RESERVED_VALUE.rawValue)])
        }else{
            if mantissa >= 0x800000 {
                mantissa = -((0xFFFFFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        
        aPointer = aPointer.advanced(by: 4)
        return output
    }
    
    static func readDateTime(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Date {
        let year  = NORCharacteristicReader.readUInt16Value(ptr: &aPointer)
        let month = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let day   = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        var hour  = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let min   = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let sec   = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        
        let dateFormatter = DateFormatter()

        var dateString : String
        if using12hClockFormat()  == true {
            var merediumString :String = "am"
            if (hour > 12) {
                hour = hour - 12;
                merediumString = "pm"
            }
            dateString = String(format: "%d %d %d %d %d %d %@", year, month, day, hour, min, sec, merediumString)
            dateFormatter.dateFormat = "yyyy MM dd HH mm ss a"
        }else{
            dateString = String(format: "%d %d %d %d %d %d", year, month, day, hour, min, sec)
            dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
        }
        return dateFormatter.date(from: dateString)!
    }
    
    static func readNibble(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> NORNibble {
        let value = NORCharacteristicReader.readUInt8Value(ptr: &aPointer)
        let nibble = NORNibble(first: value & 0xF, second: value >> 4)
        return nibble
    }
    
    static func using12hClockFormat() -> Bool {
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        return !(pmRange == nil && amRange == nil)
    }
}
