//
//  BLEManager.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BLEStatus {
    case poweredOff
    case connected(CBPeripheral)
    case disconnected
}

protocol StatusDelegate {
    func statusDidChanged(_ status: BLEStatus)
}

protocol DeviceListDelegate {
    func peripheralsFound(_ peripherals: [ScannedPeripheral])
}

protocol ConnectDelegate {
    func connect(peripheral: ScannedPeripheral)
}

class BLEManager: NSObject {
    
    let manager: CBCentralManager
    let scannUUID: [CBUUID]?
    var delegate: StatusDelegate?
    var deviceListDelegate: DeviceListDelegate?
    private var peripherals: Set<CBPeripheral> = []
    
    init(scanUUID: CBUUID?, manager: CBCentralManager = CBCentralManager()) {
        self.manager = manager
        self.scannUUID = scanUUID.map { [$0] }
        super.init()
        self.manager.delegate = self
    }
}

extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            delegate?.statusDidChanged(.poweredOff)
        case .poweredOn:
            delegate?.statusDidChanged(.disconnected)
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripherals.insert(peripheral)
        deviceListDelegate?.peripheralsFound(peripherals.map { ScannedPeripheral(with: $0, RSSI: RSSI.int32Value) } )
        Log(category: .ble, type: .debug).log(message: "Discovered peripheral: \(peripheral.name ?? "__unnamed__")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.statusDidChanged(.connected(peripheral))
        Log(category: .ble, type: .debug).log(message: "Connected to device: \(peripheral.name ?? "__unnamed__")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log(category: .ble, type: .error).log(message: error?.localizedDescription ?? "Failed to Connect: (no message)")
    }
}

extension BLEManager: ConnectDelegate {
    func connect(peripheral: ScannedPeripheral) {
        self.manager.connect(peripheral.peripheral, options: nil)
    }
}
