//
//  SernsorLocationSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class SernsorLocationSection: DetailsTableViewSection<BodySensorLocationCharacteristic> {
    override func update(with characteristic: BodySensorLocationCharacteristic) {
        items = [DefaultDetailsTableViewCellModel(title: "Sensor Location", value: characteristic.description)]
        isHidden = false 
        super.update(with: characteristic)
    }
}
