//
//  TemperatureMeasurement.swift
//  Health Thermometer
//
//  Created by Nick Kibysh on 25/01/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct ReservedFloatValues {
    static let positiveInfinity: UInt32 = 0x007FFFFE
    static let nan: UInt32 = 0x007FFFFF
    static let nres: UInt32 = 0x00800000
    static let reserved: UInt32 = 0x00800001
    static let negativeInfinity: UInt32 = 0x00800002
    
    static let firstReservedValue = ReservedFloatValues.positiveInfinity
}


func read<R: FixedWidthInteger>(_ data: Data, fromOffset offset: Int = 0) -> R {
    let length = MemoryLayout<R>.size
    guard offset + length <= data.count else { fatalError() }
    return data.subdata(in: offset ..< offset + length).withUnsafeBytes { $0.load(as: R.self) }
}

func readFloat(_ data: Data, from offset: Int = 0) -> Float {
    let tempData: UInt32 = read(data, fromOffset: offset)
    var mantissa = Int32(tempData & 0x00FFFFFF)
    let exponent = Int8(bitPattern: UInt8(tempData >> 24))
    
    var output : Float32 = 0
    
    if mantissa >= 0x800000 {
        mantissa = -((0xFFFFFF + 1) - mantissa)
    }
    let magnitude = pow(10.0, Double(exponent))
    output = Float32(mantissa) * Float32(magnitude)
    
    return output
}

struct TemperatureMeasurement: CustomDebugStringConvertible {
    enum Unit {
        case fahrenheit, celsius
    }

    var temperature: Double?
    var timestamp: Date?
    var unit: Unit

    init(data: Data) {
        let flags: UInt8 = data[0]
        let fahrenheit = flags & 0x01 == 0x01
            
        unit = fahrenheit ? .fahrenheit : .celsius
        temperature = Double(readFloat(data, from: 1))
    }
    
    var debugDescription: String {
        var s = ""
        if let temperature = temperature {
            s += "\(temperature) \(unit == .celsius ? "°C" : "°F")"
        }
        return s
    }
}
