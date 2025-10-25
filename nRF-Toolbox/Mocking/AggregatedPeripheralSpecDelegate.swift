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
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.nordicsemiUART]
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
    
    
    enum MockError: Error {
        case noDelegateToHandleRequest
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
    -> Result<Data, Error> {
        
        let results = delegates.compactMap { $0.peripheral(peripheral, didReceiveReadRequestFor: characteristic) }
        
        if let firstSuccess = results.first(where: { if case .success = $0 { return true } else { return false } }) {
            return firstSuccess
        } else {
            return .failure(MockError.noDelegateToHandleRequest)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        let results = delegates.compactMap { $0.peripheral(peripheral, didReceiveWriteRequestFor: characteristic, data: data) }
        
        if let firstSuccess = results.first(where: { if case .success = $0 { return true } else { return false } }) {
            return firstSuccess
        } else {
            return .failure(MockError.noDelegateToHandleRequest)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        let results = delegates.compactMap { $0.peripheral(peripheral, didReceiveSetNotifyRequest: enabled, for: characteristic) }
        
        if let firstSuccess = results.first(where: { if case .success = $0 { return true } else { return false } }) {
            return firstSuccess
        } else {
            return .failure(MockError.noDelegateToHandleRequest)
        }
    }
}
