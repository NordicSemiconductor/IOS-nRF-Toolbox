//
//  CharacteristicReader.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 18/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct Nibble {
    var first  : UInt8
    var second : UInt8
}

enum ReservedSFloatValues : Int16 {
    case positiveInfinity = 0x07FE
    case nan = 0x07FF
    case nres = 0x0800
    case reserved = 0x0801
    case negativeInfinity = 0x0802
    
    static let firstReservedValue = ReservedSFloatValues.positiveInfinity
}

enum ReservedFloatValues : UInt32 {
    case positiveInfinity = 0x007FFFFE
    case nan = 0x007FFFFF
    case nres = 0x00800000
    case reserved = 0x00800001
    case negativeInfinity = 0x00800002
    
    static let firstReservedValue = ReservedFloatValues.positiveInfinity
}

extension Double {
    static var reservedValues: [Double] {
        [.infinity, .nan, .nan, .nan, -.infinity]
    }
}

struct CharacteristicReader {

    static func readUInt8Value(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> UInt8 {
        let val = aPointer.pointee
        aPointer = aPointer.successor()
        return val
    }
    
    static func readSInt8Value(ptr aPointer : UnsafeMutablePointer<UInt8>) -> Int8 {
        Int8(aPointer.successor().pointee)
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
    
    static func readSFloat(_ data: Data, offset: Int) -> Float32 {
        let tempData: UInt16 = data.read(fromOffset: offset)
        var mantissa = Int16(tempData & 0x0FFF)
        var exponent = Int8(tempData >> 12)
        if exponent >= 0x0008 {
            exponent = -( (0x000F + 1) - exponent )
        }
        
        var output : Float32 = 0
        
        if mantissa >= ReservedSFloatValues.firstReservedValue.rawValue && mantissa <= ReservedSFloatValues.negativeInfinity.rawValue {
            output = Float32(Double.reservedValues[Int(mantissa - ReservedSFloatValues.firstReservedValue.rawValue)])
        } else {
            if mantissa > 0x0800 {
                mantissa = -((0x0FFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        
        return output
    }
    
    static func readSFloatValue(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Float32 {
        let tempData = CFSwapInt16LittleToHost(UnsafeMutablePointer<UInt16>(OpaquePointer(aPointer)).pointee)
        var mantissa = Int16(tempData & 0x0FFF)
        var exponent = Int8(tempData >> 12)
        if exponent >= 0x0008 {
            exponent = -((0x000F + 1) - exponent)
        }

        var output : Float32 = 0
        
        if mantissa >= ReservedSFloatValues.firstReservedValue.rawValue && mantissa <= ReservedSFloatValues.negativeInfinity.rawValue {
            output = Float32(Double.reservedValues[Int(mantissa - ReservedSFloatValues.firstReservedValue.rawValue)])
        } else {
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
        let exponent = Int8(bitPattern: UInt8(tempData >> 24))
        
        var output : Float32 = 0
        
        if mantissa >= Int32(ReservedFloatValues.firstReservedValue.rawValue) && mantissa <= Int32(ReservedFloatValues.negativeInfinity.rawValue) {
            output = Float32(Double.reservedValues[Int(mantissa - Int32(ReservedSFloatValues.firstReservedValue.rawValue))])
        } else {
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
        let year  = CharacteristicReader.readUInt16Value(ptr: &aPointer)
        let month = CharacteristicReader.readUInt8Value(ptr: &aPointer)
        let day   = CharacteristicReader.readUInt8Value(ptr: &aPointer)
        var hour  = CharacteristicReader.readUInt8Value(ptr: &aPointer)
        let min   = CharacteristicReader.readUInt8Value(ptr: &aPointer)
        let sec   = CharacteristicReader.readUInt8Value(ptr: &aPointer)
        
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
    
    static func readNibble(ptr aPointer : inout UnsafeMutablePointer<UInt8>) -> Nibble {
        let value = CharacteristicReader.readUInt8Value(ptr: &aPointer)
        let nibble = Nibble(first: value & 0xF, second: value >> 4)
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
