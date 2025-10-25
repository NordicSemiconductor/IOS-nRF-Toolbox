//
//  UARTBMPeripheralSpecDelegate.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 17/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine
import iOS_BLE_Library_Mock
import CoreBluetoothMock
import iOS_Common_Libraries

class UARTCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    let log = NordicLog(category: "UARTMock")
    
    public private(set) lazy var peripheral = CBMPeripheralSpec
        .simulatePeripheral(proximity: .far)
        .advertising(
            advertisementData: [
                CBAdvertisementDataIsConnectable : true as NSNumber,
                CBAdvertisementDataLocalNameKey : "UART",
                CBAdvertisementDataServiceUUIDsKey : [CBMUUID.nordicsemiUART]
            ],
            withInterval: 2.0,
            delay: 5.0,
            alsoWhenConnected: false
        )
        .connectable(
            name: "UART",
            services: [.uart],
            delegate: self
        )
        .build()
    
    enum MockError: Error {
        case notificationsNotEnabled, operationNotSupported, incorrectCommand
    }
    
    private var isNotificationEnabled = false
    private var messageCounter = 0
    
    public func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data) -> Result<Void, Error> {
        switch characteristic.uuid {
        case CBMUUID.rx:
            if (isNotificationEnabled) {
                let receivedMessage = String(data: data, encoding: .utf8)
                messageCounter += 1
                let reply = "Received message #\(messageCounter):\n \(receivedMessage ?? "<empty>")"
                let replyData = reply.data(using: .utf8) ?? Data()
                peripheral.simulateValueUpdate(replyData, for: CBMCharacteristicMock.uartTx)
                return .success(())
            }
            return .failure(MockError.notificationsNotEnabled)
        default:
            return .failure(MockError.operationNotSupported)
        }
    }
    
    public func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .tx:
            isNotificationEnabled = enabled
        default:
            return .failure(MockError.operationNotSupported)
        }
        
        return .success(())
    }
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .uart
    }
}

// MARK: - CoreBluetoothMock

private extension CBMUUID {
    static let rx = CBMUUID(characteristic: .nordicsemiUartRx)
    static let tx = CBMUUID(characteristic: .nordicsemiUartTx)
    
    static let clientCharacteristicConfiguration = CBMUUID(descriptor: .gattClientCharacteristicConfiguration)
}

private extension CBMDescriptorMock {
    static let clientCharacteristicConfiguration = CBMDescriptorMock(type: .clientCharacteristicConfiguration)
}

private extension CBMCharacteristicMock {
    static let uartTx = CBMCharacteristicMock(
        type: .tx,
        properties: .notify,
    )
    
    static let uartRx = CBMCharacteristicMock(
        type: .rx,
        properties: [.write],
        descriptors: .clientCharacteristicConfiguration
    )
}

private extension CBMServiceMock {
    
    static let uart = CBMServiceMock(
        type: .nordicsemiUART,
        primary: true,
        characteristics: .uartRx, .uartTx,
    )
}
