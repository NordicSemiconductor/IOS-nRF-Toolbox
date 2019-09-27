//
//  BatterySection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class BatterySection: DetailsTableViewSection {
    override func update(with data: Data) {
        let batteryLevel: UInt8 = data.read()
        let item = DefaultDetailsTableViewCellModel(title: "Battery", value: "\(batteryLevel)")
        items = [item]
    }
    
    override func reset() { }
}
