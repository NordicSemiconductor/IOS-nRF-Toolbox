//
//  GlucoseMonitorViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth



struct BGMSection: Section {
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        <#code#>
    }
    
    var numberOfItems: Int
    
    var sectionTitle: String = "Readings"
    
    
}

class GlucoseMonitorViewController: PeripheralTableViewController {
    private var bgmSection: [Section]
    
    override var sections: [Section] {
        return super.sections
    }
    
    override var profileUUID: CBUUID? {
        return CBUUID.Profile.bloodGlucoseMonitor
    }
    
    override func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        super.didDiscover(service: service, for: peripheral)
    }
    
    override func didDiscoverCharacteristics(for service: CBService) {
        super.didDiscoverCharacteristics(for: service)
    }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        super.didUpdateValue(for: characteristic)
    }
}
