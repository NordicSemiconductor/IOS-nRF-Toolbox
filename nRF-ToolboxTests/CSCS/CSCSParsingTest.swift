//
//  CSCSParsingTest.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 06/10/2025.
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
 | 0   | If wheel revolution data is present.
 | 1   | If crank revolution data is present.
 | 2–7 | Reserved (unused)
 
 ## 🛞 (Optional) Wheel revolution data

 - UInt32 for the accumulated wheel revolutions since the start of measurement.
 - UInt16 for the time in 1/1024 of second passed since the start of measurement.
 
 ## 🚴 (Optional) Crank revolution data

 - UInt16 for the accumulated crank revolutions since the start of measurement.
 - UInt16 for the time in 1/1024 of second passed since the start of measurement.
 
 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 - Wheel and crank data may be present only if feature is supported. This can be checked in another place (characteristics). Even if the feature is supported it doesn't mean the data will be present in every packet.
 - Cumulative Wheel Revolutions can decrease for backward movement.
 - Time is in 1/1024 of second.
 - UInt32 can store 4,294,967,296 wheel's revolutions. Assuming 2.1m wheel circumference it gives max distance 9,019,431km. The expected product's life expectency is 5 years with 15,000 km for an average cyclist.
 - Usual interval between measurement's notifications is 1s.
*/
class CSCSParsingTest {
    
    @Test("Test insufficient data")
    func testInsufficientData() {
        let byteArray: [UInt8] = [
            0x00
        ]
        
        let data = Data(byteArray)
        
        #expect(throws: CriticalError.noData) {
            try CyclingData(data)
        }
    }
    
    @Test("Test parse with wheel revolutions only")
    func testParseWithWheelRevolutionsOnly() {
        let byteArray: [UInt8] = [
            0x01, // Only wheel data present
            0x02,
            0x00,
            0x00,
            0x00, // 2 rotations
            0x00,
            0x04  // 1024 -> 1 second
        ]
        
        let data = Data(byteArray)
        let oldData = CyclingData()
        let result = try! CyclingData(data)
        let wheelLength = Measurement(value: 2.0, unit: UnitLength.meters)
        let expectedDistance = Measurement(value: 4.0, unit: UnitLength.meters)
        let expectedSpeed = Measurement(value: 4.0, unit: UnitSpeed.metersPerSecond)
        
        let distance = result.distance(oldData, wheelLength: wheelLength)
        let speed = result.speed(oldData, wheelLength: wheelLength)
        #expect(result.cadence(oldData) == nil)
        #expect(distance == expectedDistance)
        #expect(speed == expectedSpeed)
    }
    
    @Test("Test parse with crank revolutions only")
    func testParseWithCrankRevolutionsOnly() {
        let byteArray: [UInt8] = [
            0x02, // Only crank data is present.
            0x02,
            0x00, // 2 rotations
            0x00,
            0x04  // 1024 -> 1 second
        ]
        
        let data = Data(byteArray)
        let oldData = CyclingData()
        let result = try! CyclingData(data)
        let wheelLength = Measurement(value: 2.0, unit: UnitLength.meters)
        
        let distance = result.distance(oldData, wheelLength: wheelLength)
        let speed = result.speed(oldData, wheelLength: wheelLength)
        let cadence = result.cadence(oldData)
        #expect(cadence == 120)
        #expect(distance == nil)
        #expect(speed == nil)
    }
    
    @Test("Test parse with all data")
    func testParseWithAllData() {
        let byteArray: [UInt8] = [
            0x03, // Wheel & crank data is present
            0x02,
            0x00,
            0x00,
            0x00, // 2 rotations
            0x00,
            0x04, // 1024 -> 1 second
            0x02,
            0x00, // 2 rotations
            0x00,
            0x04  // 1024 -> 1 second
        ]
        
        let data = Data(byteArray)
        let oldData = CyclingData()
        let result = try! CyclingData(data)
        let wheelLength = Measurement(value: 2.0, unit: UnitLength.meters)
        let expectedDistance = Measurement(value: 4.0, unit: UnitLength.meters)
        let expectedSpeed = Measurement(value: 4.0, unit: UnitSpeed.metersPerSecond)
        
        let distance = result.distance(oldData, wheelLength: wheelLength)
        let speed = result.speed(oldData, wheelLength: wheelLength)
        #expect(result.cadence(oldData) == 120)
        #expect(distance == expectedDistance)
        #expect(speed == expectedSpeed)
    }
}
