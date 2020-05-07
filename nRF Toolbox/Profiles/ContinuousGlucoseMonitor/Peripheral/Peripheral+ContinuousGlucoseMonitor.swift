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
import CoreBluetooth

private extension CBUUID {
    static let feature = CBUUID(hex: 0x2AA8)
    static let measurement = CBUUID(hex: 0x2AA7)
    static let sessionRunTime = CBUUID(hex: 0x2AAB)
    static let sessionStartTime = CBUUID(hex: 0x2AAA)
    static let specificOpsControlPoint = CBUUID(hex: 0x2AAC)
    static let status = CBUUID(hex: 0x2AA9)
    static let measurementContext = CBUUID(hex: 0x2A34)
    static let recordAccessPoint = CBUUID(hex: 0x2A52)
}

extension PeripheralDescription {
    static let continuousGlucoseMonitor = PeripheralDescription(uuid: CBUUID(hex: 0x181F), services: [.battery, .continuousGlucoseMonitor], mandatoryServices: [CBUUID(hex: 0x181F)],
        mandatoryCharacteristics: [
        ])
}

private extension PeripheralDescription.Service {
    static let continuousGlucoseMonitor = PeripheralDescription.Service(uuid: CBUUID(hex: 0x181F), characteristics: [.feature, .measurement, .sessionRunTime, .sessionStartTime, .specificOpsControlPoint, .status])
}

private extension PeripheralDescription.Service.Characteristic {
    static let feature = PeripheralDescription.Service.Characteristic(uuid: .feature, properties: .read)
    static let measurement = PeripheralDescription.Service.Characteristic(uuid: .measurement, properties: .notify(true))
    static let sessionRunTime = PeripheralDescription.Service.Characteristic(uuid: .sessionRunTime, properties: .read)
    static let sessionStartTime = PeripheralDescription.Service.Characteristic(uuid: .sessionStartTime, properties: .read)
    static let specificOpsControlPoint = PeripheralDescription.Service.Characteristic(uuid: .specificOpsControlPoint, properties: .read)
    static let status = PeripheralDescription.Service.Characteristic(uuid: .status, properties: .read)
    static let measurementContext = PeripheralDescription.Service.Characteristic(uuid: .measurementContext, properties: .read)
    static let recordAccessPoint = PeripheralDescription.Service.Characteristic(uuid: .recordAccessPoint, properties: .read)
}

