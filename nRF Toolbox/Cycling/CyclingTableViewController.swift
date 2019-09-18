//
//  CyclingTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class CyclingTableViewController: PeripheralTableViewController {
    private var cyclingSection = CyclingTableViewSection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "DetailsTableViewCell")
    }
    
    override var internalSections: [Section] {
        return [cyclingSection]
    }
    
    override var profileUUID: CBUUID? {
        return CBUUID.Profile.cyclingSpeedCadenceSensor
    }
    
    override var scanServices: [CBUUID]? {
        return (super.scanServices ?? []) + [CBUUID.Service.cyclingSpeedCadenceSensor]
    }
    
    override func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        switch service.uuid {
        case CBUUID.Service.cyclingSpeedCadenceSensor:
            peripheral.discoverCharacteristics([CBUUID.Characteristics.CyclingSesnor.measurement], for: service)
        default:
            super.didDiscover(service: service, for: peripheral)
        }
    }
    
    override func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        switch (service.uuid, characteristic.uuid) {
        case (CBUUID.Service.cyclingSpeedCadenceSensor, CBUUID.Characteristics.CyclingSesnor.measurement):
            peripheral.setNotifyValue(true, for: characteristic)
        default:
            super.didDiscover(characteristic: characteristic, for: service, peripheral: peripheral)
        }
    }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.CyclingSesnor.measurement:
            guard let value = characteristic.value else {
                fallthrough
            }
            handleCycling(value: value)
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
    
    private func handleCycling(value: Data) {
        cyclingSection.update(with: value)
        reloadSection(id: "cycling")
    }
}


