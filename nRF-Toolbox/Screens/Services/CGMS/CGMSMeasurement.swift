//
//  CGMSMeasurement.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 2/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation
import iOS_Common_Libraries

// MARK: - CGMSMeasurement

struct CGMSMeasurement {
    
    // MARK: Properties
    
    let measurement: Measurement<UnitConcentrationMass>
    let timeOffset: Int
    let date: Date
    
    let sensorStatus: BitField<CGMSSensorStatusOctet>?
    let calTempStatus: BitField<CGMSCalTempOctet>?
    let warningStatus: BitField<CGMSWarningOctet>?
    
    let trend: Measurement<UnitGlucoseTrend>?
    let quality: Float?
    let crc: UInt16?
    
    let size: Int
    let measuredSize: Int
    
    let calculatedCrc: UInt16?

    // MARK: init
    
    init(data: Data, sessionStartTime: Date) throws {
        var offset = 0
        
        self.size = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
        offset += MemoryLayout<UInt8>.size
        
        let flags = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
        let isTrendDataPresent = flags & 1 > 0
        let isQualityDataPresent = flags & 2 > 0
        let isWarningOctetPresent = flags & 32 > 0
        let isCalTempOctetPresent = flags & 64 > 0
        let isStatusOctetPresent = flags & 128 > 0
        offset += MemoryLayout<UInt8>.size

        let sFloatBytes = data.subdata(in: offset..<offset + SFloatReserved.byteSize)
        let value = Float(asSFloat: sFloatBytes)
        measurement = Measurement<UnitConcentrationMass>(value: Double(value), unit: .milligramsPerDeciliter)
        offset += SFloatReserved.byteSize
        
        timeOffset = data.littleEndianBytes(atOffset: offset, as: UInt16.self)
        date = sessionStartTime.addingTimeInterval(TimeInterval(timeOffset * 60))
        offset += MemoryLayout<UInt16>.size
        
        if isStatusOctetPresent {
            let byte = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
            self.sensorStatus = BitField(RegisterValue(byte))
            offset += MemoryLayout<UInt8>.size
        } else {
            self.sensorStatus = nil
        }
        
        if isCalTempOctetPresent {
            let byte = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
            self.calTempStatus = BitField(RegisterValue(byte))
            offset += MemoryLayout<UInt8>.size
        } else {
            self.calTempStatus = nil
        }
        
        if isWarningOctetPresent {
            let byte = data.littleEndianBytes(atOffset: offset, as: UInt8.self)
            self.warningStatus = BitField(RegisterValue(byte))
            offset += MemoryLayout<UInt8>.size
        } else {
            self.warningStatus = nil
        }
        
        if isTrendDataPresent {
            let sFloatBytes = data.subdata(in: offset..<offset + SFloatReserved.byteSize)
            let value = Float(asSFloat: sFloatBytes)
            self.trend = Measurement<UnitGlucoseTrend>(value: Double(value), unit: .milligramsPerDecilitrePerMinute)
            offset += SFloatReserved.byteSize
        } else {
            self.trend = nil
        }
        
        if isQualityDataPresent {
            let sFloatBytes = data.subdata(in: offset..<offset + SFloatReserved.byteSize)
            self.quality = Float(asSFloat: sFloatBytes)
            offset += SFloatReserved.byteSize
        } else {
            self.quality = nil
        }

        if offset + MemoryLayout<UInt16>.size <= size {
            self.crc = data.littleEndianBytesUInt16(atOffset: offset)
            self.calculatedCrc = CRC16.mcrf4xx(data: data, offset: 0, length: offset)
            offset += MemoryLayout<UInt16>.size
        } else {
            self.crc = nil
            self.calculatedCrc = nil
        }
        
        self.measuredSize = offset
    }
    
    // MARK: API
    
    func toStringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("E d MMM yyyy HH:mm:ss")
        return dateFormatter.string(from: date)
    }
    
    func isCrcValid() -> Bool? {
        guard let crc, let calculatedCrc else { return nil }
        return crc == calculatedCrc
    }
}

// MARK: - CustomStringConvertible

extension CGMSMeasurement: CustomStringConvertible {
    
    var description: String {
        return measurement.formatted()
    }
}
