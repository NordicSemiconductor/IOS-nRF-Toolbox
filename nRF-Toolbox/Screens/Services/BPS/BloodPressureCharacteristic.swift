//
//  BloodPressureCharacteristic.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 3/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - BloodPressureCharacteristic

struct BloodPressureCharacteristic {
    
    // MARK: Properties
    
//    let systolicPressure: Measurement<UnitPressure>
//    let diastolicPressure: Measurement<UnitPressure>
//    let meanArterialPressure: Measurement<UnitPressure>
    let date: Date?
    let pulseRate: Int?
    
    // MARK: init
    
    init(data: Data) throws {
        let flags = try data.littleEndianBytes(as: UInt8.self)
//        let unit: UnitPressure = Flag.isAvailable(bits: flags, flag: .unitFlag) ? .millimetersOfMercury : .kilopascals
        
        var offset = 1
        let systolicValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        offset += SFloatReserved.byteSize
        let diastolicValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        offset += SFloatReserved.byteSize
        let meanArterialValue = Float(asSFloat: data.subdata(in: offset..<offset + SFloatReserved.byteSize))
        offset += SFloatReserved.byteSize
        
        date = nil
        pulseRate = nil
//        var offset = 7
//        date = try Flag.isAvailable(bits: flags, flag: .timeStamp) ? {
//                defer { offset += 7 }
//                return try data.readDate(from: offset)
//            }() : nil
//        
//        pulseRate = try Flag.isAvailable(bits: flags, flag: .pulseRate) ? {
//                let pulseValue = try data.readSFloat(from: offset)
//                return Int(pulseValue)
//            }() : nil
    }
}

//private extension Flag {
//    static let unitFlag: Flag = 0x01
//    static let timeStamp: Flag = 0x02
//    static let pulseRate: Flag = 0x04
//}
