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

class GLSParsingTest {
    
    @Test("Test insufficient data")
    func testInsufficientData() {
        let byteArray: [UInt8] = [0x00]
        
        let data = Data(byteArray)
        let result = GlucoseMeasurement(data)
        
        #expect(result == nil)
    }
    
    @Test("Test missing mandatory fields")
    func testMissingMandatoryFields() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: No optional fields
            0xE4,
            0x07,   // Year: 2020 (little-endian)
            0x05,   // Month: May
            0x15,   // Day: 21
            0x0A,   // Hour: 10
            0x1E,   // Minute: 30
            0x2D    // Second: 45
        ]
        
        // TODO: Looks like the glucose value is missing.
        
        let data = Data(byteArray)
        let result = GlucoseMeasurement(data)

        #expect(result == nil)
    }
    
    @Test("Test only required fields")
    func testOnlyMandatoryFields() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: No optional fields
            0x01,
            0x00,   // Sequence Number
            0xE4,
            0x07,   // Year: 2020 (little-endian)
            0x05,   // Month: May
            0x15,   // Day: 21
            0x0A,   // Hour: 10
            0x1E,   // Minute: 30
            0x2D,   // Second: 45
        ]
        
        // TODO: Looks like the glucose value is missing.
        
        let data = Data(byteArray)
        let result = GlucoseMeasurement(data)!
        let calendar = Calendar(identifier: .gregorian)
        
        let day = calendar.component(.day, from: result.timestamp)
        let month = calendar.component(.month, from: result.timestamp)
        let year = calendar.component(.year, from: result.timestamp)
        let hour = calendar.component(.hour, from: result.timestamp)
        let minute = calendar.component(.minute, from: result.timestamp)
        let second = calendar.component(.second, from: result.timestamp)
        
        #expect(result.sequenceNumber == 1)
        #expect(year == 2020)
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
            0xE4,
            0x07,  // Year: 2020 (little-endian)
            0x05,  // Month: May
            0x15,  // Day: 21
            0x0A,  // Hour: 10
            0x1E,  // Minute: 30
            0x2D,  // Second: 45
            0x00,
            0x00,  // Time Offset: 0 minutes
            0x51,
            0x00,
            0x14,  // Glucose concentration (IEEE 11073 format) and type/sample location
            0x06,
            0x00,  // Sensor Status Annunciation
        ]
        
        // TODO: Looks like the glucose value is missing.
        
        let data = Data(byteArray)
        let result = GlucoseMeasurement(data)!
        let calendar = Calendar(identifier: .gregorian)
        
        let day = calendar.component(.day, from: result.timestamp)
        let month = calendar.component(.month, from: result.timestamp)
        let year = calendar.component(.year, from: result.timestamp)
        let hour = calendar.component(.hour, from: result.timestamp)
        let minute = calendar.component(.minute, from: result.timestamp)
        let second = calendar.component(.second, from: result.timestamp)
        
        #expect(result.sequenceNumber == 2)
        #expect(year == 2020)
        #expect(month == 5)
        #expect(day == 21)
        #expect(hour == 10)
        #expect(minute == 30)
        #expect(second == 45)
        #expect(result.measurement == Measurement(value: 81.0, unit: .millimolesPerLiter(withGramsPerMole: .bloodGramsPerMole)))
        #expect(result.timeOffset == Measurement(value: 0, unit: .minutes))
        #expect(result.sensorLocation == .finger)
        #expect(result.sensorType == .venousPlasma)
    }
}
