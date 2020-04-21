//
//  BatterySection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 10/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class BatterySection: DetailsTableViewSection<BatteryCharacteristic> {
    override func reset() { }
    
    override func update(with characteristic: BatteryCharacteristic) {
        let item = DefaultDetailsTableViewCellModel(title: "Battery", value: "\(characteristic.batteryLevel)")
        items = [item]
    }
    
}
