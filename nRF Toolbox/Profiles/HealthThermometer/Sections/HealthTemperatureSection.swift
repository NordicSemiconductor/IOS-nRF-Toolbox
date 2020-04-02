//
//  HealthTemperatureSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class HealthTemperatureSection: DetailsTableViewSection<HealthTermometerCharacteristic> {
    override func update(with characteristic: HealthTermometerCharacteristic) {
        let formatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        formatter.numberFormatter = numberFormatter
        
        items = [DefaultDetailsTableViewCellModel(title: "Temperature", value: formatter.string(from: characteristic.temperature))]
        super.update(with: characteristic)
    }
}
