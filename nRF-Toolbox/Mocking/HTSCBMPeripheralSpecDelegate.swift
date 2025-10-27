//
//  HTSCBMPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 15/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

class HTSCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    let log = NordicLog(category: "HealthThermometerMock")
    lazy var cancellables = Set<AnyCancellable>()
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "Health thermometer",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.healthThermometer]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "Health Thermometer Sensor",
            services: [.temperature],
            delegate: self
        )
        .build()
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .temperature
    }
    
    func generateData() -> Data {
        return Data(
            [
                0x06,
                UInt8.random(in: 0...255),       // Temperature byte 1 (LSB)
                0x0E,       // Temperature byte 2
                0x00,       // Temperature byte 3
                0xFE,       // Temperature byte 4 (MSB)
                0xE9,       // Year LSB (2025)
                0x07,       // Year MSB (2025)
                UInt8.random(in: 1...12),       // Month
                UInt8.random(in: 1...28),       // Day
                0x0A,       // Hour: 10
                0x1E,       // Minute: 30
                0x2D,       // Second: 45
                UInt8.random(in: 1...9)        // Body location
            ]
        )
    }
    
    let featureResponse = Data([0x00, 0x00])

    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .temperatureMeasurement:
            Timer.publish(every: 2.0, on: .main, in: .default)
                .autoconnect()
                .sink { [unowned self] _ in
                    peripheral.simulateValueUpdate(self.generateData(), for: characteristic)
                }
                .store(in: &cancellables)
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                           data: Data) -> Result<Void, Error> {
        return .failure(MockError.writingIsNotSupported)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, any Error> {
        return .failure(MockError.readingIsNotSupported)
    }
}

// MARK: - CoreBluetoothMock

private extension CBMUUID {
    static let temperatureMeasurement = CBMUUID(characteristic: .temperatureMeasurement)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let temperatureMeasurement = CBMCharacteristicMock(
        type: .temperatureMeasurement,
        properties: .notify,
        descriptors: .clientCharacteristicConfiguration
    )
}

private extension CBMServiceMock {
    
    static let temperature = CBMServiceMock(
        type: .healthThermometer,
        primary: true,
        characteristics: .temperatureMeasurement,
    )
}
