//
//  ByteByfferExt.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 10/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import NIO
import iOS_Common_Libraries

public extension Data {
    
    func toByteBuffer() -> ByteBuffer {
        var buffer = ByteBufferAllocator().buffer(capacity: count)
        buffer.writeBytes(self)
        return buffer
    }
}

public extension ByteBuffer {
    
    mutating func read<R: FixedWidthInteger>() throws -> R {
        let length = MemoryLayout<R>.size

        
        guard readerIndex + MemoryLayout<R>.size <= writerIndex else {
            throw ParsingError.invalidSize(actualSize: writerIndex, expectedSize: readerIndex + MemoryLayout<R>.size)
        }

        return readBytes(length: length)!.withUnsafeBytes {
            $0.load(as: R.self)
        }
    }
    
    mutating func readDate(from offset: Int = 0) throws -> Date {
        guard readerIndex + Date.DataSize <= writerIndex else {
            throw ParsingError.invalidSize(actualSize: writerIndex, expectedSize: readerIndex + Date.DataSize )
        }
        
        let year: UInt16 = readInteger(endianness: .little)!
        let month: UInt8 = readInteger(endianness: .little)!
        let day: UInt8 = readInteger(endianness: .little)!
        let hour: UInt8 = readInteger(endianness: .little)!
        let min: UInt8 = readInteger(endianness: .little)!
        let sec: UInt8 = readInteger(endianness: .little)!
        
        let calendar = Calendar.current
        let dateComponents = DateComponents(calendar: .current,
                       year: Int(year),
                       month: Int(month),
                       day: Int(day),
                       hour: Int(hour),
                       minute: Int(min),
                       second: Int(sec))
        
        return calendar.date(from: dateComponents)!
    }
    
    mutating func readSFloat() throws -> Float? {
        guard readerIndex + SFloatReserved.byteSize <= writerIndex else {
            throw ParsingError.invalidSize(actualSize: writerIndex, expectedSize: readerIndex + SFloatReserved.byteSize)
        }
        
        guard let raw: UInt16 = readInteger(endianness: .little) else {
            return nil
        }

        // 12-bit mantissa + 4-bit exponent (IEEE-11073)
        var mantissa = Int16(raw & 0x0FFF)
        if mantissa >= 0x0800 { mantissa -= 0x1000 }  // znak

        var exponent = Int8((raw & 0xF000) >> 12)
        if exponent >= 0x08 { exponent = exponent - 0x10 } // znak

        return Float(mantissa) * pow(10.0, Float(exponent))
    }
    
    mutating func readDouble() throws -> Double? {
        if let value = try readSFloat() {
            return Double(value)
        }
        return nil
    }
}
