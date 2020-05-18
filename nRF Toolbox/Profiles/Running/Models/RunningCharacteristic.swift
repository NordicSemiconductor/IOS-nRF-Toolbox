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
    static let strideLength: Flag = 0x01
    static let totalDistance: Flag = 0x02
    static let isRunning: Flag = 0x04
}

struct RunningCharacteristic {
    
    let instantaneousSpeed: Measurement<UnitSpeed>
    let instantaneousCadence: Int
    let instantaneousStrideLength: Measurement<UnitLength>?
    let totalDistance: Measurement<UnitLength>?
    let isRunning: Bool
     
    init(data: Data) throws {
        let instantaneousSpeedValue = Double(try data.read(fromOffset: 1) as UInt16) / 256
        instantaneousSpeed = Measurement(value: instantaneousSpeedValue, unit: .metersPerSecond)
        instantaneousCadence = Int(try data.read(fromOffset: 3) as UInt8)
        
        let bitFlags: UInt8 = try data.read(fromOffset: 0)
        
        isRunning = Flag.isAvailable(bits: bitFlags, flag: .isRunning)
        
        instantaneousStrideLength = try Flag.isAvailable(bits: bitFlags, flag: .strideLength) ? {
                let strideLengthValue: UInt16 = try data.read(fromOffset: 4)
                return Measurement(value: Double(strideLengthValue), unit: .centimeters)
            }() : nil
        
        totalDistance = try Flag.isAvailable(bits: bitFlags, flag: .totalDistance) ? {
                let totalDistanceValue: UInt32 = try data.read(fromOffset: 6)
                return Measurement(value: Double(totalDistanceValue), unit: .decameters)
            }() : nil
    }
}
