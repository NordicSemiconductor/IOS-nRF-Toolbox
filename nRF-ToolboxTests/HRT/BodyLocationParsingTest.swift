//
//  BodyLocationTest.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 29/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//
import Testing
import Foundation
import iOS_Common_Libraries
@testable import nRF_Toolbox

/**
    Body sensor location is UInt8 defined in "GATT Specificatio Supplement".
    The values that are not specified are treated as "reserved for future use" and should be treated as not present in HRM.
 */
class BodyLocationParsingTest {
    
    @Test("Test valid body location")
    func testValidBodyLocation() {
        let byteArray: [UInt8] = [0x03]
        let data = Data(byteArray)
        // FIX: Correct initializer usage
        let sensorLocation = HeartRateMeasurement.SensorLocation(rawValue: RegisterValue(data[0]))
        
        #expect(sensorLocation == .finger, "Sensor location 0x03 should be .finger")
    }
    
    @Test("Test invalid body location")
    func testInvalidBodyLocation() {
        let byteArray: [UInt8] = [0x08]
        let data = Data(byteArray)
        // FIX: Correct initializer usage
        let sensorLocation = HeartRateMeasurement.SensorLocation(rawValue: RegisterValue(data[0]))
        
        #expect(sensorLocation == nil, "Sensor location fiels is not valid. Fallback to nil.")
    }
}
