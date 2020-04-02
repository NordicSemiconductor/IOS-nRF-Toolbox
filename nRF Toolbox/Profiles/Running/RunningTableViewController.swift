//
//  RunningTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

private extension Identifier where Value == Section {
    static let runningSpeedCadence: Identifier<Section> = "runningSpeedCadence"
    static let runningActivitySection: Identifier<Section> = "runningActivitySection"
}

class RunningTableViewController: PeripheralTableViewController {
    lazy private var runningSpeedCadenceSection = RunningSpeedSection.init(id: .runningSpeedCadence, itemUpdated: { [weak self] (section, item) in
            self?.reloadItemInSection(section, itemId: item, animation: .none)
        })
    private let activitySection = ActivitySection(id: .runningActivitySection)
    override var peripheralDescription: PeripheralDescription { .runningSpeedCadenceSensor }
    override var internalSections: [Section] { [activitySection, runningSpeedCadenceSection] }
    override var navigationTitle: String { "Running Speed and Cadence" }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.Running.measurement:
            characteristic.value.map {
                let running = RunningCharacteristic(data: $0)
                runningSpeedCadenceSection.update(with: running)
                activitySection.update(with: running)
                
                tableView.reloadData()
            }
            
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}
