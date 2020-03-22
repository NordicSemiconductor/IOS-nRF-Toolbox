//
//  DFUDeviceInfoSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUDeviceInfoSection: DFUActionSection {
    var peripheral: Peripheral
    let action: () -> ()
    
    init(peripheral: Peripheral, action: @escaping () -> ()) {
        self.peripheral = peripheral
        self.action = action
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        guard index != 2 else {
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Choose another device"
            return cell
        }
        
        let cell = tableView.dequeueCell(ofType: NordicRightDetailTableViewCell.self)
        let title = index == 0 ? "Name" : "Status"
        let details = index == 0 ? peripheral.name : peripheral.peripheral.state.description
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = details
        cell.selectionStyle = .none
        
        return cell
    }
    
    func reset() {
         
    }
    
    var numberOfItems: Int {
        3
    }
    
    var sectionTitle: String {
        "Device Info"
    }
    
    var id: Identifier<Section> {
        "DFUDeviceInfoSection"
    }
    
    var isHidden: Bool { false }
    
    
}
