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
        
        #expect(result.totalDistance == Measurement(value: 4096, unit: .meters))
        #expect(result.instantaneousStrideLength == 800)
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
