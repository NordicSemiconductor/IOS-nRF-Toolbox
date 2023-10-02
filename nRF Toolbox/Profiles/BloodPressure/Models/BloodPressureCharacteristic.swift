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

private extension Flag {
    static let unitFlag: Flag = 0x01
    static let timeStamp: Flag = 0x02
    static let pulseRate: Flag = 0x04
}

struct BloodPressureCharacteristic {
    
    let systolicPressure: Measurement<UnitPressure>
    let diastolicPressure: Measurement<UnitPressure>
    let meanArterialPressure: Measurement<UnitPressure>
    let date: Date?
    let pulseRate: Int?
    
    init(data: Data) throws {
        let flags: UInt8 = try data.read(fromOffset: 0)
        let unit: UnitPressure = Flag.isAvailable(bits: flags, flag: .unitFlag) ? .millimetersOfMercury : .kilopascals
        
        let systolicValue: Float32 = try data.readSFloat(from: 1)
        let diastolicValue: Float32 = try data.readSFloat(from: 3)
        let meanArterialValue: Float32 = try data.readSFloat(from: 5)
        
        systolicPressure = Measurement<UnitPressure>(value: Double(systolicValue), unit: unit)
        diastolicPressure = Measurement<UnitPressure>(value: Double(diastolicValue), unit: unit)
        meanArterialPressure = Measurement<UnitPressure>(value: Double(meanArterialValue), unit: unit)
        
        var offset = 7
        date = try Flag.isAvailable(bits: flags, flag: .timeStamp) ? {
                defer { offset += 7 }
                return try data.readDate(from: offset)
            }() : nil
        
        pulseRate = try Flag.isAvailable(bits: flags, flag: .pulseRate) ? {
                let pulseValue = try data.readSFloat(from: offset)
                return Int(pulseValue)
            }() : nil
    }
}
