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

// MARK: UART

class UARTCBMPeripheralSpecDelegate: MockSpecDelegate {
    
    private var isNotificationEnabled = false
    private var messageCounter = 0
    
    private let log = NordicLog(category: "UARTMock")
    
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
            delegate: self,
            connectionInterval: 0.02,
        )
        .build()
    
    func getMainService() -> CoreBluetoothMock.CBMServiceMock {
        .uart
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
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
            return .failure(MockError.writingIsNotSupported)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveSetNotifyRequest enabled: Bool, for characteristic: CBMCharacteristicMock) -> Result<Void, Error> {
        switch characteristic.uuid {
        case .tx:
            isNotificationEnabled = enabled
        default:
            return .failure(MockError.notifyIsNotSupported)
        }
        
        return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didReceiveReadRequestFor characteristic: CBMCharacteristicMock) -> Result<Data, any Error> {
        return .failure(MockError.readingIsNotSupported)
    }
}
