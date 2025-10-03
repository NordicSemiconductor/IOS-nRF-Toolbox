//
//  BPSParsingTest.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 03/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Testing
import Foundation
@testable import nRF_Toolbox

class BPSParsingTest {
    
    @Test("Test parsing all fields.")
    func testParsingAllFields() {
        let byteArray: [UInt8] = [
            0x1f,   // Flags: All fields present
            0x79,
            0x00,   // Systolic: 121
            0x51,
            0x00,   // Diastolic: 81
            0x6a,
            0x00,   // Mean Arterial Pressure: 106
            0xE4,   // Year LSB (2020)
            0x07,   // Year MSB (2020)
            0x05,   // Month: May
            0x15,   // Day: 21
            0x0A,   // Hour: 10
            0x1E,   // Minute: 30
            0x2D,   // Second: 45
            0x48,
            0x00,   // Pulse Rate: 72.0 bpm
            0x01,   // User ID: 1
            0x06,
            0x00    // Measurement Status: Irregular pulse detected
        ]
        
        let data = Data(byteArray)
        let result = (try? BloodPressureMeasurement(data: data))!
        let calendar = Calendar(identifier: .gregorian)
        
        let day = calendar.component(.day, from: result.date!)
        let month = calendar.component(.month, from: result.date!)
        let year = calendar.component(.year, from: result.date!)
        let hour = calendar.component(.hour, from: result.date!)
        let minute = calendar.component(.minute, from: result.date!)
        let second = calendar.component(.second, from: result.date!)
        
        #expect(result.diastolicPressure == Measurement(value: 81, unit: .kilopascals))
        #expect(result.systolicPressure == Measurement(value: 121, unit: .kilopascals))
        #expect(result.meanArterialPressure == Measurement(value: 106, unit: .kilopascals))
        #expect(year == 2020)
        #expect(month == 5)
        #expect(day == 21)
        #expect(hour == 10)
        #expect(minute == 30)
        #expect(second == 45)
        #expect(result.pulseRate == 72)
        #expect(result.userID == 1)
        #expect(result.status?.contains(.irregularPulse) == true)
    }
    
    @Test("Test parsing mandatory fields.")
    func testParsingMandatoryFields() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: No optional fields
            0x48,
            0x00,   // Systolic: 72.0 mmHg
            0x51,
            0x00,   // Diastolic: 81.0 mmHg
            0x40,
            0x00    // Mean Arterial Pressure: 64.0 mmHg
        ]
        
        let data = Data(byteArray)
        let result = (try? BloodPressureMeasurement(data: data))!
        
        #expect(result.diastolicPressure == Measurement(value: 81, unit: .millimetersOfMercury))
        #expect(result.systolicPressure == Measurement(value: 72, unit: .millimetersOfMercury))
        #expect(result.meanArterialPressure == Measurement(value: 64, unit: .millimetersOfMercury))
        #expect(result.pulseRate == nil)
        #expect(result.userID == nil)
        #expect(result.status == nil)
        #expect(result.date == nil)
    }
    
    
    @Test("Test parsing invalid data length.")
    func testParsingInvalidDataLength() {
        let byteArray: [UInt8] = [
            0x00,   // Flags: No optional fields
            0x48,
            0x00
        ]
        
        let data = Data(byteArray)
        let result = try? BloodPressureMeasurement(data: data)
        
        #expect(result == nil)
    }
}
