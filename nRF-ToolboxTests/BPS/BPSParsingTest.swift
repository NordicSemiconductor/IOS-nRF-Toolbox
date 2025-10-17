//
//  BPSParsingTest.swift
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
 | 0   | Unit flag: 0 - mmHg, 1 - kPa
 | 1   | If time stamp present.
 | 2   | If pulse rating present.
 | 3   | If user ID present.
 | 4   | If measurement status present.
 | 5–7 | Reserved (unused)
 
 ## 🩺 Systolic Pressure

 - SFLOAT (2 bytes).
 - Unit depends on flag field and can be mmHg or kPa.
 - Reserved value 0x07FF for errors.
 
 ## 🩸 Diastolic Pressure

 - SFLOAT (2 bytes).
 - Unit depends on flag field and can be mmHg or kPa.
 - Reserved value 0x07FF for errors.
 
 ## 🫀 Mean Arterial Pressure

 - SFLOAT (2 bytes).
 - Unit depends on flag field and can be mmHg or kPa.
 - Reserved value 0x07FF for errors.
 
 ## 🕒 (Optional) Timestamp

 - 7 bytes in format yyyy:mm:dd hh:mm:ss
 - Mandatory if time stamp feature is supported.
 - 0 should not be used for month and day, but can be used for year if a device doesn't support it.
 
 ## 💓 (Optional) Pulse rate

 - SFLOAT (2 bytes).
 - In beats per minute.
 - Reserved value 0x07FF for errors.
 
 ## 👤 (Optional) User ID

 - UInt8 to identify user for a case when a sensor can be shared between multiple users.
 - Possible values: 0x00–0xFE for identified users and reserved value 0xFF for unknown user.
 
 ## 🧾 (Optional) Measurement status

 - 2 bytes for a status.
 - 0 values in status means that things are ok.

 | Bit | Meaning |
 |-------|---------|
 | 0     | 0 if body haven't moved during measurement.
 | 1     | 0 if cuff fit properly.
 | 2     | 0 if no irregular pulse detected.
 | 3-4  | 00 - pulse rate withing range, 01 - above upper limit, 10 - below lower limit, 11 - reserved
 | 5     | 0 if proper measurement position.
 | 6–7 | Reserved (unused)
 
 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 - Some of pressure values may be not available in the record. Then special reserved value NaN will be sent.
 
*/
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
            0x00    // Measurement Status: Irregular pulse detected and loose cuff
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
        #expect(result.status?.contains(.cuffFitLoose) == true)
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
        
        #expect(throws: ParsingError.invalidSize(actualSize: 3, expectedSize: 5)) {
            try BloodPressureMeasurement(data: data)
        }
    }
}
