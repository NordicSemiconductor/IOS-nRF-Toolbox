//
//  HeartRateSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class HeartRateSection: DetailsTableViewSection<HeartRateMeasurementCharacteristic> {
    override func update(with characteristic: HeartRateMeasurementCharacteristic) {
        items = [DefaultDetailsTableViewCellModel(title: "Heart Rate", value: "\(characteristic.heartRate) BPM")]
        super.update(with: characteristic)
    }
}
