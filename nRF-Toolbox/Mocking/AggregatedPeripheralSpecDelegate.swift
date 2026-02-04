//
//  AggregatedPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 25/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

class AggregatedPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    
    let delegates: [MockSpecDelegate]
    
    init(delegates: [MockSpecDelegate]) {
        self.delegates = delegates
    }
    
    let log = NordicLog(category: "AggregatedMock")
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "All in One",
                CBAdvertisementDataServiceUUIDsKey : delegates.map { $0.getMainService().uuid }
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "All in One",
            services: delegates.map { $0.getMainService() },
            delegate: self
        )
        .build()
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, Error> {
        for delegate in delegates {
            if characteristic.service?.uuid != delegate.getMainService().uuid {
                continue
            }
            let result = delegate.peripheral(peripheral, didReceiveReadRequestFor: characteristic)
            if case .success = result {
                return result
            }
        }
        return .failure(MockError.readingIsNotSupported)
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        for delegate in delegates {
            if characteristic.service?.uuid != delegate.getMainService().uuid {
                continue
            }
            let result = delegate.peripheral(peripheral, didReceiveWriteRequestFor: characteristic, data: data)
            if case .success = result {
                return result
            }
        }
        return .failure(MockError.writingIsNotSupported)
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        for delegate in delegates {
            if characteristic.service?.uuid != delegate.getMainService().uuid {
                continue
            }
            let result = delegate.peripheral(peripheral, didReceiveSetNotifyRequest: enabled, for: characteristic)
            if case .success = result {
                return result
            }
        }
        return .failure(MockError.notifyIsNotSupported)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: (any Error)?) {
        for delegate in delegates {
            delegate.peripheral(peripheral, didDisconnect: error)
        }
    }
}
