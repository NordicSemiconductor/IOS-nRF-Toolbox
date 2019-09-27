//
//  RunningTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class RunningTableViewController: PeripheralTableViewController {
    lazy private var cyclingSpeedCadenceSection = RunningSpeedSection.init(id: .runningSpeedCadence, itemUpdated: { [weak self] (section, item) in
            self?.reloadItemInSection(section, itemId: item, animation: .none)
        })
    private let activitySection = ActivitySection(id: .runningActivitySection)
    override var peripheralDescription: Peripheral { Peripheral.runningSpeedCadenceSensor }
    override var internalSections: [Section] { [activitySection, cyclingSpeedCadenceSection] }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.Running.measurement:
            characteristic.value.map {
                self.cyclingSpeedCadenceSection.update(with: $0)
                self.reloadSection(id: .runningSpeedCadence)
                
                self.activitySection.update(with: $0)
                self.reloadSection(id: .runningActivitySection)
            }
            
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}
