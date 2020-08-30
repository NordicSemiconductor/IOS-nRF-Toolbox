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


import Core
import Foundation

private extension Flag {
    static let wheelData: Flag = 0x01
    static let crankData: Flag = 0x02
}

struct CyclingCharacteristic {
    
    typealias WheelRevolutionAndTime = (revolution: Int, time: Double)
    
    let wheelRevolutionsAndTime: WheelRevolutionAndTime?
    let crankRevolutionsAndTime: WheelRevolutionAndTime?
    
    static let zero = CyclingCharacteristic(wheelRevolutionsAndTime: (0, 0.0), crankRevolutionsAndTime: (0, 0.0))
    
    init(wheelRevolutionsAndTime: (Int, Double)?, crankRevolutionsAndTime: (Int, Double)?) {
        self.wheelRevolutionsAndTime = wheelRevolutionsAndTime
        self.crankRevolutionsAndTime = crankRevolutionsAndTime
    }
    
    init(data: Data) throws {
        let flags: UInt8 = try data.read()
        
        wheelRevolutionsAndTime = try Flag.isAvailable(bits: flags, flag: .wheelData) ? {
                (
                    Int(try data.read(fromOffset: 1) as UInt32),
                    Double(try data.read(fromOffset: 5) as UInt16)
                )
            }() : nil
        
        let crankOffset: (Int, Int) = Flag.isAvailable(bits: flags, flag: .wheelData) ? (7, 9) : (1, 3)
        
        crankRevolutionsAndTime = try Flag.isAvailable(bits: flags, flag: .crankData) ? {
                (
                    Int(try data.read(fromOffset: crankOffset.0) as UInt16),
                    Double(try data.read(fromOffset: crankOffset.1) as UInt16)
                )
            }() : nil
    }
    
    func travelDistance(with wheelCircumference: Double) -> Measurement<UnitLength>? {
        wheelRevolutionsAndTime.map { Measurement<UnitLength>(value: Double($0.revolution) * wheelCircumference, unit: .meters) }
    }
    
    func distance(_ oldCharacteristic: CyclingCharacteristic, wheelCircumference: Double) -> Measurement<UnitLength>? {
        wheelRevolutionDiff(oldCharacteristic)
            .flatMap { Measurement<UnitLength>(value: Double($0) * wheelCircumference, unit: .meters) }
    }
    
    func gearRatio(_ oldCharacteristic: CyclingCharacteristic) -> Double? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(oldCharacteristic), let crankRevolutionDiff = crankRevolutionDiff(oldCharacteristic), crankRevolutionDiff != 0 else {
            return nil
        }
        return Double(wheelRevolutionDiff) / Double(crankRevolutionDiff)
    }
    
    func speed(_ oldCharacteristic: CyclingCharacteristic, wheelCircumference: Double) -> Measurement<UnitSpeed>? {
        guard let wheelRevolutionDiff = wheelRevolutionDiff(oldCharacteristic), let wheelEventTime = wheelRevolutionsAndTime?.time, let oldWheelEventTime = oldCharacteristic.wheelRevolutionsAndTime?.time else {
            return nil
        }
        
        var wheelEventTimeDiff = wheelEventTime - oldWheelEventTime
        guard wheelEventTimeDiff > 0 else {
            return nil
        }
        
        wheelEventTimeDiff /= 1024
        let speed = (Double(wheelRevolutionDiff) * wheelCircumference) / wheelEventTimeDiff
        return Measurement<UnitSpeed>(value: speed, unit: .milesPerHour)
    }
    
    func cadence(_ oldCharacteristic: CyclingCharacteristic) -> Int? {
        guard let crankRevolutionDiff = crankRevolutionDiff(oldCharacteristic), let crankEventTimeDiff = crankEventTimeDiff(oldCharacteristic), crankEventTimeDiff > 0 else {
            return nil
        }
        
        return Int(Double(crankRevolutionDiff) / crankEventTimeDiff * 60.0)
    }
    
    private func wheelRevolutionDiff(_ oldCharacteristic: CyclingCharacteristic) -> Int? {
        guard let oldWheelRevolution = oldCharacteristic.wheelRevolutionsAndTime?.revolution, let wheelRevolution = wheelRevolutionsAndTime?.revolution else {
            return nil
        }
        guard oldWheelRevolution != 0 else { return 0 }
        return wheelRevolution - oldWheelRevolution
    }
    
    private func crankRevolutionDiff(_ old: CyclingCharacteristic) -> Int? {
        guard let crankRevolution = crankRevolutionsAndTime?.revolution, let oldCrankRevolution = old.crankRevolutionsAndTime?.revolution else {
            return nil
        }
        
        return crankRevolution - oldCrankRevolution
    }
    
    private func crankEventTimeDiff(_ old: CyclingCharacteristic) -> Double? {
        guard let crankEventTime = crankRevolutionsAndTime?.time, let oldCrankEventTime = old.crankRevolutionsAndTime?.time else {
            return nil
        }
        return (crankEventTime - oldCrankEventTime) / 1024.0
    }
}
