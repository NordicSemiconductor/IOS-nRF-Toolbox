//
//  HeartMeasurementParsingTest.swift
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
 ## 🎌 Flags Byte (bit-wise breakdown):

 Each bit in the `Flags` (first byte) determines the format and presence of subsequent fields.

 | Bit | Meaning |
 |-----|---------|
 | 0   | Heart Rate Format: `0 = UInt8`, `1 = UInt16`
         - `UInt16` used for high HR values (e.g., animals > 255 bpm)
 | 1   | Sensor Contact Detected (`1 = yes`)
 | 2   | Sensor Contact Feature Supported
 | 3   | Energy Expended field present
 | 4   | RR-Intervals are present
 | 5–7 | Reserved (unused)

 ## ❤️ Heart Rate Value

 - Format: `UInt8` or `UInt16` depending on **bit 0** of the `Flags` byte.
 - Value is in **BPM** (beats per minute).

 ## 🔋 Energy Expended (Optional)

 - Format: `UInt16`
 - Represents energy used, in kilojoules since the last time it was reset..
 - Present only if **bit 3** of `Flags` is set.
 - Typically occurs once in ten measurements.

 ## 🕐 RR-Intervals (Optional)

 - Format: One or more values of `UInt16` (each 2 bytes)
 - Each value represents the time (in **1/1024 seconds**) between successive heartbeats.
 - Present only if **biRt 4** of `Flags` is set.
 - Used for heart rate variability (HRV) analysis.

 ## 📌 Notes

 - All multibyte values are **Little Endian**.
 - If more RR-Interval values are measured since the last notification than fit into one Heart Rate Measurement characteristic, then the remaining RR-Interval values should be included in the next available Heart Rate Measurement characteristic.
 - If there is no available space in the internal buffer of the Heart Rate Sensor, it may discard the oldest RR-Interval values.
*/
class HeartMeasurementParsingTest {
    
    @Test("Test measurement data with one rr-interval")
    func testMeasurementDataWithOneRRInterval() {
        let byteArray: [UInt8] = [0x14, 0xAA, 0x8D, 0x00]
        let data = Data(byteArray)
        // FIX: Correct initializer usage
        let heartRateMeasurement = HeartRateMeasurement(data)
        
        print(heartRateMeasurement)
        
        #expect(heartRateMeasurement.heartRateValue == 170)
        #expect(heartRateMeasurement.energyExpended == nil)
        #expect(heartRateMeasurement.sensorContact == .supportedButNotDetected)
        #expect(heartRateMeasurement.intervals == [TimeInterval(137.6953125)])
    }
    
    @Test("Test measurement data with energy expended and one rr-interval")
    func testMeasurementDataWithEnergyExpendedAndOneRRInterval() {
        let byteArray: [UInt8] = [0x1C, 0xAA, 0x8D, 0x00, 0x8D, 0x00]
        let data = Data(byteArray)
        // FIX: Correct initializer usage
        let heartRateMeasurement = HeartRateMeasurement(data)
        
        print(heartRateMeasurement)
        
        #expect(heartRateMeasurement.heartRateValue == 170)
        #expect(heartRateMeasurement.energyExpended == 141)
        #expect(heartRateMeasurement.sensorContact == .supportedButNotDetected)
        #expect(heartRateMeasurement.intervals == [TimeInterval(137.6953125)])
    }
    
    @Test("Test measurement data with only bpm")
    func testMeasurementDataWithOnlyBpm() {
        let byteArray: [UInt8] = [0x00, 0xAA]
        let data = Data(byteArray)
        // FIX: Correct initializer usage
        let heartRateMeasurement = HeartRateMeasurement(data)
        
        print(heartRateMeasurement)
        
        #expect(heartRateMeasurement.heartRateValue == 170)
        #expect(heartRateMeasurement.energyExpended == nil)
        #expect(heartRateMeasurement.sensorContact == .notSupported)
        #expect(heartRateMeasurement.intervals == nil)
    }
    
    @Test("Test measurement data with sensor contact and empty intervals")
    func testMeasurementDataWithSensorContactAndEmptyIntervals() {
        let byteArray: [UInt8] = [0x06, 0xAA]
        let data = Data(byteArray)
        // FIX: Correct initializer usage
        let heartRateMeasurement = HeartRateMeasurement(data)
        
        print(heartRateMeasurement)
        
        #expect(heartRateMeasurement.heartRateValue == 170)
        #expect(heartRateMeasurement.energyExpended == nil)
        #expect(heartRateMeasurement.sensorContact == .supportedAndDetected)
        #expect(heartRateMeasurement.intervals == nil)
    }
}
