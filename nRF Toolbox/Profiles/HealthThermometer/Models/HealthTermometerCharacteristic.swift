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
