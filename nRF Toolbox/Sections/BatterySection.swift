//
//  BatterySection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct BatterySection: Section {
    let id = Identifier.TableSection.battery
    
    let numberOfItems = 1
    let sectionTitle = "Battery"
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Battery")
        cell?.textLabel?.text = "Battery: \(self.batteryLevel)"
        return cell!
    }
    
    var batteryLevel: Int = 0
}
