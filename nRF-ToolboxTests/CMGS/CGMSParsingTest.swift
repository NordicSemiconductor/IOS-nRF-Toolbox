//
//  CGMSParsingTest.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 07/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Testing
import Foundation
@testable import nRF_Toolbox

/**
 ## 📏 Size
 
 - UInt8 the size of a packet.
 - The minimum size is 6 octects.
 - The size field is itself included in the measurement.
 
 ## 🎌 Flags Byte (bit-wise breakdown):

 UInt8, each bit in the `Flags` (first byte) determines the format and presence of subsequent fields.

 | Bit | Meaning |
 |-----|---------|
 | 0   | CGM trend information present.
 | 1   | CGM quality present.
 | 2   | Reserved for future use.
 | 3   | Reserved for future use.
 | 4   | Reserved for future use.
 | 5   | Sensor Status Annunciation field, Warning-Octet present
 | 6   | Sensor Status Annunciation field, Cal/Temp-Octet present
 | 7   | Sensor Status Annunciation field, Status-Octet present
 
 ## 🧪 Glucose concentration

 - SFLOAT (2 bytes).
 - Unit is milligram per decilite.
 
 ## 🕒 Time offset

 - UInt16 number of minutes since start time.
 
 ## ⚙️ (Optional) Sensor Status Annunciation field, Status-Octet
 
 - 1 octet, bit field.
 - This field tells about general status of the sensor.
 
 | Bit  | Meaning |
 |------|---------|
 | 0    | Session stopped.
 | 1    | Device battery low.
 | 2    | Sensor type incorrect for device.
 | 3    | Sensor malfunction.
 | 4    | Device Specific Alert.
 | 5    | General device fault has occurred in the sensor.
 | 6-7 | Reserved for Future Use.
 
 ## 🌡️ (Optional) Sensor Status Annunciation field, Cal/Temp-Octet
 
 - 1 octet, bit field.
 - This field tells about calibration status of the sensor and temperature which is important because it can influence glucose measurement.
 
 | Bit  | Meaning |
 |------|---------|
 | 0    | Time synchronization between sensor and collector required.
 | 1    | Calibration not allowed.
 | 2    | Calibration recommended.
 | 3    | Calibration required.
 | 4    | Sensor temperature too high for valid test/result at time of measurement.
 | 5    | Sensor temperature too low for valid test/result at time of measurement.
 | 6-7 | Reserved for Future Use.
 
 ## ⚠️ (Optional) Sensor Status Annunciation field, Warning-Octet
 
 - 1 octet, bit field.
 - This field informs about potential alerting situations.
 
 | Bit | Meaning |
 |-----|---------|
 | 0   | Sensor result lower than the Patient Low level.
 | 1   | Sensor result higher than the Patient High level.
 | 2   | Sensor result lower than the Hypo level.
 | 3   | Sensor result higher than the Hyper level.
 | 4   | Sensor Rate of Decrease exceeded.
 | 5   | Sensor Rate of Increase exceeded.
 | 6   | Sensor result lower than the device can process.
 | 7   | Sensor result higher than the device can process.
 
 ## 📉 (Optional) CGM Trend information
 
 - 2 bytes SFLOAT in mg per decilitre / minute.
 
 ## 🔎 (Optional) CGM quality
 
 - 2 bytes SFLOAT in percentage.
 
 ## 🔐 (Optional) E2E-CRC
 
 - Present if supported. The information can be obtained from Feature characteristic.
 - UInt16 w CRC code.
 
 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 - Measurements can be received in periodic or requested manner. Periodic means that only 1 record is returned with the latest value and requested can return multiple records at once.
 
*/
class CGMSParsingTest {
    
    let sessionStart = Date(timeIntervalSince1970: 0)
    
    @Test("Test crc.")
    func testCRC() {
        let byteArray: [UInt8] = [
            0x3E,
            0x01,
            0x02,
            0x03,
            0x04,
            0x05,
            0x06,
            0x07,
            0x08,
            0x09,
        ]
        let data = Data(byteArray)
        
        let crc = CRC16.mcrf4xx(data: byteArray, offset: 0, length: byteArray.count)
        #expect(crc == 12033)
    }
    
    @Test("Test data with all valid fields.")
    func testDataWithAllValidFields() {
        let byteArray: [UInt8] = [
            0x0F,  // Size: 15 bytes (6 base + 2 trend + 2 quality + 1 warning + 1 temp + 1 status + 2 CRC + size)
            0xE3,  // Flags: All optional fields present (binary 11100011)
            0x78,
            0x00,  // Glucose concentration: 120 mg/dL
            0x1E,
            0x00,  // Time offset: 30 minutes
            0x01,  // Sensor status
            0x02,  // Calibration temp status
            0x03,  // Warning status
            0x50,
            0x00,  // Trend: 80 mg/dL/min
            0x60,
            0x00,  // Quality: 96 mg/dL
            0xEC,
            0xAC   // CRC: Placeholder (valid CRC for this data)
        ]
        let data = Data(byteArray)
        let results = CGMSMeasurementParser.parse(data: data, sessionStartTime: sessionStart)
        let result = results[0]
        
        #expect(results.count == 1)
        #expect(result.measurement == Measurement(value: Double(120.0), unit: .milligramsPerDeciliter))
        #expect(result.date == sessionStart.addingTimeInterval(30*60))
        #expect(result.sensorStatus?.contains(.sessionStopped) == true)
        #expect(result.sensorStatus?.count == 1)
        #expect(result.calTempStatus?.contains(.calibrationNotAllowed) == true)
        #expect(result.calTempStatus?.count == 1)
        #expect(result.warningStatus?.contains(.resultLowerThanThePatientLowLevel) == true)
        #expect(result.warningStatus?.contains(.resulthigherThanThePatientHightLevel) == true)
        #expect(result.warningStatus?.count == 2)
        #expect(result.trend == Measurement(value: 80, unit: .milligramsPerDecilitrePerMinute))
        #expect(result.quality == 96.0)
        #expect(result.crc == 44268)
        #expect(result.calculatedCrc == 44268)
    }
    
    @Test("Test data with only mandatory fields.")
    func testDataWithOnlyMandatoryFields() {
        let byteArray: [UInt8] = [
            0x06,  // Size: 6 bytes (base packet size without any optional fields)
            0x00,  // Flags: No optional fields present
            0x78,
            0x00,  // Glucose concentration: 120 mg/dL
            0x1E,
            0x00  // Time offset: 30 minutes
        ]
        let data = Data(byteArray)
        let results = CGMSMeasurementParser.parse(data: data, sessionStartTime: sessionStart)
        let result = results[0]
        
        #expect(results.count == 1)
        #expect(result.measurement == Measurement(value: Double(120.0), unit: .milligramsPerDeciliter))
        #expect(result.date == sessionStart.addingTimeInterval(30*60))
        #expect(result.sensorStatus == nil)
        #expect(result.calTempStatus == nil)
        #expect(result.warningStatus == nil)
        #expect(result.trend == nil)
        #expect(result.quality == nil)
        #expect(result.crc == nil)
    }
    
    @Test("Test many records.")
    func testManyRecords() {
        let byteArray: [UInt8] = [
            0x06,  // Size: 6 bytes (base packet size without any optional fields)
            0x00,  // Flags: No optional fields present
            0x78,
            0x00,  // Glucose concentration: 120 mg/dL
            0x1E,
            0x00,  // Time offset: 30 minutes
            0x06,  // Size: 6 bytes (base packet size without any optional fields)
            0x00,  // Flags: No optional fields present
            0x77,
            0x00,  // Glucose concentration: 119 mg/dL
            0x1D,
            0x00,  // Time offset: 29 minutes
        ]
        let data = Data(byteArray)
        let results = CGMSMeasurementParser.parse(data: data, sessionStartTime: sessionStart)
        let result0 = results[0]
        let result1 = results[1]
        
        #expect(results.count == 2)
        #expect(result0.measurement == Measurement(value: Double(120.0), unit: .milligramsPerDeciliter))
        #expect(result0.date == sessionStart.addingTimeInterval(30*60))
        #expect(result0.sensorStatus == nil)
        #expect(result0.calTempStatus == nil)
        #expect(result0.warningStatus == nil)
        #expect(result0.trend == nil)
        #expect(result0.quality == nil)
        #expect(result0.crc == nil)
        #expect(result1.measurement == Measurement(value: Double(119.0), unit: .milligramsPerDeciliter))
        #expect(result1.date == sessionStart.addingTimeInterval(29*60))
        #expect(result1.sensorStatus == nil)
        #expect(result1.calTempStatus == nil)
        #expect(result1.warningStatus == nil)
        #expect(result1.trend == nil)
        #expect(result1.quality == nil)
        #expect(result1.crc == nil)
    }
    
    @Test("Test data with incorrect size.")
    func testDataWithIncorrectSize() {
        let byteArray: [UInt8] = [
            0x05,  // Size: 5 bytes (less than minimum size of 6)
            0x00,  // Flags: No optional fields present
            0x78,
            0x00,  // Glucose concentration: 120 mg/dL
            0x1E  // Incomplete time offset
        ]
        let data = Data(byteArray)
        let results = CGMSMeasurementParser.parse(data: data, sessionStartTime: sessionStart)
        
        #expect(results.count == 0)
    }
    
    @Test("Test data with mismatched CRC.")
    func testDataWithMismatchedCrc() {
        let byteArray: [UInt8] = [
            0x08,  // Size: 8 bytes (6 base + 2 CRC)
            0x00,  // Flags: No optional fields present
            0x78,
            0x00,  // Glucose concentration: 120 mg/dL
            0x1E,
            0x00,  // Time offset: 30 minutes
            0x12,
            0x34   // CRC: Invalid placeholder
        ]
        let data = Data(byteArray)
        let results = CGMSMeasurementParser.parse(data: data, sessionStartTime: sessionStart)
        let result = results[0]
        
        #expect(results.count == 1)
        #expect(result.calculatedCrc == 39220)
        #expect(result.isCrcValid() == false)
    }
}
