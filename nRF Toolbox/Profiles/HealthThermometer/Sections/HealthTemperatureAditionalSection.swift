//
//  HealthTemperatureAditionalSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 07/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class HealthTemperatureAditionalSection: DetailsTableViewSection<HealthTermometerCharacteristic> {
    
    override var isHidden: Bool { false }
    
    override init(id: Identifier<Section>, sectionUpdated: ((Identifier<Section>) -> ())? = nil, itemUpdated: ((Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ())? = nil) {
        super.init(id: id, sectionUpdated: sectionUpdated, itemUpdated: itemUpdated)
    }
    
    override func update(with characteristic: HealthTermometerCharacteristic) {
        
        var items: [DetailsTableViewCellModel] = []
        
        characteristic.timeStamp.map {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: $0)
            items.append(DefaultDetailsTableViewCellModel(title: "Date / Time", value: dateString))
        }
        
        characteristic.type.map {
            items.append(DefaultDetailsTableViewCellModel(title: "Location", value: $0.description))
        }
        
        self.items = items
        
        super.update(with: characteristic)
    }
}
