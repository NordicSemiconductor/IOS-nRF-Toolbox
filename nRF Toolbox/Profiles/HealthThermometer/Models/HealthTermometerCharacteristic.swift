//
//  HealthTermometerCharacteristic.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

private extension Flag {
    static let unit: Flag = 0x01
    static let timestamp: Flag = 0x02
    static let type: Flag = 0x04
}

struct HealthTermometerCharacteristic {
    
    enum TemperatureType: UInt8, CustomStringConvertible {
        var description: String {
            switch self {
            case .armpit: return "Armpit"
            case .bodyGeneral: return "Body - general"
            case .ear: return "Ear"
            case .finger: return "Finger"
            case .gastroIntenstinalTract: return "Gastro-intenstinal Tract"
            case .mouth: return "Mouth"
            case .rectum: return "Rectum"
            case .toe: return "Toe"
            case .tympanumEarDrum: return "Tympanum - ear drum"
            }
        }
        
        case armpit=1, bodyGeneral, ear, finger, gastroIntenstinalTract, mouth, rectum, toe, tympanumEarDrum
    }
    
    let temperature: Measurement<UnitTemperature>
    
    let timeStamp: Date?
    let type: TemperatureType?
    
    init(data: Data) {
        let flags: UInt8 = data.read()
        let unit: UnitTemperature = Flag.isAvailable(bits: flags, flag: .unit) ? .fahrenheit : .celsius
        
        let temperatureValue = data.readFloat(from: 1)
        temperature = Measurement<UnitTemperature>(value: Double(temperatureValue), unit: unit)
        
        var offset = 5
        timeStamp = Flag.isAvailable(bits: flags, flag: .timestamp) ? {
                defer { offset += 7 }
                return data.readDate(from: offset)
            }() : nil
        
        type = Flag.isAvailable(bits: flags, flag: .type) ? {
                let typeValue: UInt8 = data.read(fromOffset: offset)
                return TemperatureType(rawValue: typeValue)
            }() : nil
    }
}
