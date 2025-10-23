//
//  GLSParsingTest.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 03/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Testing
import Foundation
import iOS_Common_Libraries
@testable import nRF_Toolbox

/**
 ## 🎌 Flags Byte (bit-wise breakdown):

 UInt8, each bit in the `Flags` (first byte) determines the format and presence of subsequent fields.

 | Bit  | Meaning |
 |------|---------|
 | 0    | If time offset present.
 | 1    | If Glucose Concentration and Type-Sample Location present.
 | 2    | Glucose unit: 0 - mg/dL, 1 - mmol/L.
 | 3    | If sensor status annunciation present.
 | 4    | If context information present.
 | 5-7 | Reserved for future use.
 
 ## 🔢 Sequence number

 - UInt16 representing chronological order of items starting from 0.
 
 ## 🕒 Base time

 - 7 bytes in format yyyy:mm:dd hh:mm:ss
 
 ## ⌛ (Optional) Time offset
 
 - Int16 in minutes.
 - Time difference to base time.
 
 ## 🧪 (Optional) Glucose concentration
 
 - SFLOAT 2 bytes. Depending
 - Unit depends on a flag bit nr 2.
 
 ## 🦶 (Optional) Type-Sample location
 
 - UInt8 defining Type-Sample location.
 - Most significant nibble - location, least significant nibble - type
 
 ## ⚠️ (Optional) Sensor status
 
 - 2 octets.
 
 | Bit  | Meaning |
 |------|---------|
 | 0    | Device battery low.
 | 1    | Sensor malfunction at the time of measurement.
 | 2    | Sample size insufficient (not enough blood druing the measurement).
 | 3    | Strip insertion error.
 | 4    | Strip type incorrect.
 | 5    | Sensor result too high.
 | 6    | Sensor result too low.
 | 7    | Sensor temperature too high.
 | 8    | Sensor temperature too low.
 | 9    | Sensor read interrupted, the strip was pulled too soon.
 | 10  | General device fault.
 | 11  | Time fault.
 | 12-15 | Reserved for future use.
 
 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 
*/
class GLSParsingTest {
    
    @Test("Test insufficient data")
    func testInsufficientData() {
        let byteArray: [UInt8] = [0x00]
        
        let data = Data(byteArray)
        
        #expect(throws: ParsingError.invalidSize(actualSize: 1, expectedSize: 3)) {
            try GlucoseMeasurement(data)
        }
    }
    
    @Test("Test missing mandatory fields")
    func testMissingMandatoryFields() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: No optional fields
            0xE9,
            0x07,   // Year: 2025 (little-endian)
            0x05,   // Month: May
            0x15,   // Day: 21
            0x0A,   // Hour: 10
            0x1E,   // Minute: 30
            0x2D    // Second: 45
        ]
        
        // TODO: Looks like the glucose value is missing.
        
        let data = Data(byteArray)

        #expect(throws: ParsingError.invalidSize(actualSize: 8, expectedSize: 10)) {
            try GlucoseMeasurement(data)
        }
    }
    
    @Test("Test only required fields")
    func testOnlyMandatoryFields() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: No optional fields
            0x01,
            0x00,   // Sequence Number
            0xE9,
            0x07,   // Year: 2025 (little-endian)
            0x05,   // Month: May
            0x15,   // Day: 21
            0x0A,   // Hour: 10
            0x1E,   // Minute: 30
            0x2D,   // Second: 45
        ]
        
        // TODO: Looks like the glucose value is missing.
        
        let data = Data(byteArray)
        let result = try! GlucoseMeasurement(data)
        let calendar = Calendar(identifier: .gregorian)
        
        let day = calendar.component(.day, from: result.timestamp)
        let month = calendar.component(.month, from: result.timestamp)
        let year = calendar.component(.year, from: result.timestamp)
        let hour = calendar.component(.hour, from: result.timestamp)
        let minute = calendar.component(.minute, from: result.timestamp)
        let second = calendar.component(.second, from: result.timestamp)
        
        #expect(result.sequenceNumber == 1)
        #expect(year == 2025)
        #expect(month == 5)
        #expect(day == 21)
        #expect(hour == 10)
        #expect(minute == 30)
        #expect(second == 45)
    }
    
    @Test("Test with all optional fields")
    func testWithAllOptionalFields() {
        let byteArray: [UInt8] = [
            0x1F,  // Flags: All optional fields present
            0x02,
            0x00,  // Sequence Number
            0xE9,
            0x07,  // Year: 2025 (little-endian)
            0x05,  // Month: May
            0x15,  // Day: 21
            0x0A,  // Hour: 10
            0x1E,  // Minute: 30
            0x2D,  // Second: 45
            0x00,
            0x00,  // Time Offset: 0 minutes
            0x78,
            0x00,  // Glucose concentration (IEEE 11073 format) and type/sample location
            0x41,  // 4 - location, 1 - type
            0x01,
            0x00,  // Status - device battery low
        ]
        
        // TODO: Looks like the glucose value is missing.
        
        let data = Data(byteArray)
        let result = try! GlucoseMeasurement(data)
        let calendar = Calendar(identifier: .gregorian)
        
        let day = calendar.component(.day, from: result.timestamp)
        let month = calendar.component(.month, from: result.timestamp)
        let year = calendar.component(.year, from: result.timestamp)
        let hour = calendar.component(.hour, from: result.timestamp)
        let minute = calendar.component(.minute, from: result.timestamp)
        let second = calendar.component(.second, from: result.timestamp)
        
        #expect(result.sequenceNumber == 2)
        #expect(year == 2025)
        #expect(month == 5)
        #expect(day == 21)
        #expect(hour == 10)
        #expect(minute == 30)
        #expect(second == 45)
        #expect(result.measurement == Measurement(value: 120.0, unit: .millimolesPerLiter(withGramsPerMole: .bloodGramsPerMole)))
        #expect(result.timeOffset == Measurement(value: 0, unit: .minutes))
        #expect(result.sensorLocation == .controlSolution)
        #expect(result.sensorType == .capillaryBlood)
        #expect(result.status?.contains(.deviceBatteryLow) == true)
    }
}
