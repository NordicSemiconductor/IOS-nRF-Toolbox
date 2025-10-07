//
//  RSCSParsingTest.swift
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

 Each bit in the `Flags` (first byte) determines the format and presence of subsequent fields.

 | Bit | Meaning |
 |-----|---------|
 | 0   | If stride length data is present.
 | 1   | If total distance data is present.
 | 2   | (Optional) Walking - 0 or running - 1.
 | 3–7 | Reserved (unused)
 
 ## 🏃‍♂️ Instantaneous Speed

 - UInt16 for instantaneous speed in 1/256 of m/s.
 
 ## ⏱️ Instantaneous Cadence

 - UInt8 for instantaneous cadence in step/second.
 
 ## 🦶 (Optional) Stride Length

 - UInt16 for the stride length in centimiters.
 
 ## 📏 (Optional) Total Distance

 - UInt32 for the total distance since the start of measurement in decimiters.
 
 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 - Walking or running flag field is present only if feature is supported. This can be checked in another place (characteristics).
 - Usual interval between measurement's notifications is 1s.
 - Total distance is UInt32 and can store 429,496.7296 km. Assuming produc lifetime 5 years and top runners may reach 10,000km in that time then it should be more than enough.
 - Pay attention to units as those are tricky.
 
*/
class RSCSParsingTest {
    
    @Test("Test parse with all fields present.")
    func testParsingWithoutOptionalFields() {
        let byteArray: [UInt8] = [
            0x07,  // Flags: all fields present (0b00000111)
            0x80,
            0x02,  // Speed: 640 [0x0280] -> 2.5 m/s (640 / 256)
            0x50,  // Cadence: 80
            0x20,
            0x03,  // Stride length: 800 [0x0320]
            0x00,  // Total distance: 4096 [0x00100000]
            0x10,
            0x00,
            0x00
        ]
        
        let data = Data(byteArray)
        let result = RSCSMeasurement(from: data)
        
        #expect(result.totalDistance == Measurement(value: 4096, unit: .decimeters))
        #expect(result.instantaneousStrideLength == Measurement(value: 800, unit: .centimeters))
        #expect(result.instantaneousCadence == 80)
        #expect(result.instantaneousSpeed == Measurement(value: 2.5, unit: .metersPerSecond))
    }
    
    @Test("Test parse with only mandatory fields.")
    func testParsingWithOnlyMandatoryFields() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: no optional fields (0b00000000)
            0x80,
            0x02,   // Speed: 640 [0x0280] -> 2.5 m/s (640 / 256)
            0x50    // Cadence: 80
        ]
        
        let data = Data(byteArray)
        let result = RSCSMeasurement(from: data)
        
        #expect(result.totalDistance == nil)
        #expect(result.instantaneousStrideLength == nil)
        #expect(result.instantaneousCadence == 80)
        #expect(result.instantaneousSpeed == Measurement(value: 2.5, unit: .metersPerSecond))
    }
    
    @Test("Test parse with insufficient data.")
    func testParsingWithInsufficientData() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: no optional fields
            0x80    // Incomplete speed data
        ]
        
        let data = Data(byteArray)
        let result = RSCSMeasurement(from: data)
        
        #expect(result.totalDistance == nil)
        #expect(result.instantaneousStrideLength == nil)
        #expect(result.instantaneousCadence == 0)
        #expect(result.instantaneousSpeed.value.isNaN)
    }
}
