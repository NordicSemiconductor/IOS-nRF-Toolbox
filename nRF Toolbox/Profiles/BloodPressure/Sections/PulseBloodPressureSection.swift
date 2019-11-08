//
//  PulseBloodPressureSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class PulseBloodPressureSection: DetailsTableViewSection<BloodPreasureCharacteristic> {
    override func update(with characteristic: BloodPreasureCharacteristic) {
        guard let heartRate = characteristic.pulseRate else {
            reset()
            return
        }
        
        items = [DefaultDetailsTableViewCellModel(title: "Heart Rate", value: "\(heartRate)")]
        super.update(with: characteristic)
    }
}
