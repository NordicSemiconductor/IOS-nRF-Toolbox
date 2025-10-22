//
//  HealthThermometerParsingTest.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 02/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Testing
import Foundation
import iOS_Common_Libraries
@testable import nRF_Toolbox

/**
 ## 🎌 Flags Byte (bit-wise breakdown):

 Each bit in the `Flags` (first byte) determines the format and presence of subsequent fields.

 | Bit | Meaning |
 |-----|---------|
 | 0   | Temperature Format: `0 = Celsius`, `1 = Fahrenheit`
 | 1   | If timestamp is present
 | 2   | If temperature Type field is present
 | 3–7 | Reserved (unused)
 
 ## 🌡️ Temperature value

 - IEEE-11073 32-bit float.
 - Don't forget it's little endian.
 - First 24-bits it's a mantissa other 8 is magnitude.
 - The equation for calculating a number is: mantissa * 10^magnitude.
 - Value 0x007FFFFF is reserved and means NaN.

 ## ⏰ (Optional) Timestamp
 
 Timestamp has the following format:
 - 2 bytes little endian - year
 - 1 byte - month
 - 1 byte - day
 - 1 byte - hour
 - 1 byte - minutes
 - 1 byte - seconds

 ## 📍 (Optional) Temperature type

 - Indicates a place of measurement.
 - Values are available in "GATT Specification Supplement 5".

 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 
*/
class HealthThermometerParsingTest {
    
    @Test("Test parsing with all data.")
    func testParsingWithAllData() {
        let byteArray: [UInt8] = [
            0x06,
            0x71,       // Temperature byte 1 (LSB)
            0x0E,       // Temperature byte 2
            0x00,       // Temperature byte 3
            0xFE,       // Temperature byte 4 (MSB)
            0xE4,       // Year LSB (2020)
            0x07,       // Year MSB (2020)
            0x05,       // Month: May
            0x15,       // Day: 21
            0x0A,       // Hour: 10
            0x1E,       // Minute: 30
            0x2D,       // Second: 45
            0x01        // Type 1: Armpit
        ]
        let data = Data(byteArray)
        let result = try! TemperatureMeasurement(data)
        
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: result.timestamp!)
        let month = calendar.component(.month, from: result.timestamp!)
        let year = calendar.component(.year, from: result.timestamp!)
        let hour = calendar.component(.hour, from: result.timestamp!)
        let minute = calendar.component(.minute, from: result.timestamp!)
        let second = calendar.component(.second, from: result.timestamp!)
        
        #expect(result.temperature == Measurement(value: 36.97, unit: UnitTemperature.celsius))
        #expect(result.location == .armpit)
        #expect(day == 21)
        #expect(month == 5)
        #expect(year == 2020)
        #expect(hour == 10)
        #expect(minute == 30)
        #expect(second == 45)
    }
    
    @Test("Test parsing without optional fields.")
    func testParsingWithoutOptionalFields() {
        let byteArray: [UInt8] = [
            0x00,
            0xC4,
            0x09,
            0x00,
            0xFE,
        ]
        
        let data = Data(byteArray)
        let result = try! TemperatureMeasurement(data)
        
        #expect(result.temperature == Measurement(value: 25.0, unit: UnitTemperature.celsius))
        #expect(result.location == nil)
        #expect(result.timestamp == nil)
    }
    
    @Test("Test parsing with invalid float.")
    func testParsingWithInvalidFloat() {
        let byteArray: [UInt8] = [
            0x00,
            0xFF,
            0xFF,
            0x7F,
            0x00,
        ]
        
        let data = Data(byteArray)
        
        let result = try! TemperatureMeasurement(data)
        
        #expect(result.temperature.value.isNaN)
        #expect(result.location == nil)
        #expect(result.timestamp == nil)
    }
    
    @Test("Test parsing with insufficient byte array.")
    func testParsingWithInsufficientArray() {
        let byteArray: [UInt8] = [0x00]
        
        let data = Data(byteArray)
        
        #expect(throws: ParsingError.invalidSize(actualSize: 1, expectedSize: 5)) {
            try TemperatureMeasurement(data)
        }
    }
}
