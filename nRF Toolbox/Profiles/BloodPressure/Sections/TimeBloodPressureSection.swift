//
//  TimeBloodPressureSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class TimeBloodPressureSection: DetailsTableViewSection<BloodPressureCharacteristic> {
    override func update(with characteristic: BloodPressureCharacteristic) {
        guard let date = characteristic.date else {
            reset()
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        
        items = [DefaultDetailsTableViewCellModel(title: "Date / Time", value: dateFormatter.string(from: date))]
        
        super.update(with: characteristic)
    }
}
