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
    let sequenceNumber: Int
    private let date: Date

    // MARK: init
    
    init(data: Data, sessionStartTime: Date) throws {
        guard data.count >= MemoryLayout<UInt16>.size * 2 else {
            throw Data.DataError.insufficientData
        }
        
        let offset = MemoryLayout<UInt16>.size
        let sFloatBytes = data.subdata(in: offset..<offset + SFloatReserved.byteSize)
        let value = Float(asSFloat: sFloatBytes)
        measurement = Measurement<UnitConcentrationMass>(value: Double(value), unit: .milligramsPerDeciliter)
        let unsignedNumber: UInt16 = try data.read(fromOffset: MemoryLayout<UInt16>.size * 2)
        sequenceNumber = Int(unsignedNumber)
        date = sessionStartTime.addingTimeInterval(TimeInterval(sequenceNumber * 60))
    }
    
    // MARK: API
    
    func toStringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("E d MMM yyyy HH:mm:ss")
        return dateFormatter.string(from: date)
    }
}

// MARK: - CustomStringConvertible

extension CGMSMeasurement: CustomStringConvertible {
    
    var description: String {
        return String(format: "%.2f \(measurement.unit.symbol)", measurement.value)
    }
}
