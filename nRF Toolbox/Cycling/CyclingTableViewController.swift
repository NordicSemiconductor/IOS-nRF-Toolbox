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
    
    override var peripheralDescription: Peripheral {
        return .cyclingSpeedCadenceSensor
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


