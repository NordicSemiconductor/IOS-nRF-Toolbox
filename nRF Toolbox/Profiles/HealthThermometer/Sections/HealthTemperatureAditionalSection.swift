//
//  HealthTemperatureAditionalSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 07/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class HealthTemperatureAditionalSection: DetailsTableViewSection<HealthTermometerCharacteristic> {
    override func update(with characteristic: HealthTermometerCharacteristic) {
        
        var items: [DetailsTableViewCellModel] = []
        
        characteristic.timeStamp.map {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: $0)
            items.append(DefaultDetailsTableViewCellModel(title: "Date/Time", value: dateString))
        }
        
        characteristic.type.map {
            items.append(DefaultDetailsTableViewCellModel(title: "Location", value: $0.description))
        }
        
        self.items = items
        isHidden = items.count == 0
        
        super.update(with: characteristic)
    }
}
