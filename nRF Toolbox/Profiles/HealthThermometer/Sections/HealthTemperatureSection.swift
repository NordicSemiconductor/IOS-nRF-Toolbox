//
//  HealthTemperatureSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class HealthTemperatureSection: DetailsTableViewSection<HealthTermometerCharacteristic> {
    
    override var isHidden: Bool {
        return false
    }
    
    override func reset() {
        items = [DefaultDetailsTableViewCellModel(title: "Temperature", value: "-")]
    }
    
    override init(id: Identifier<Section>, sectionUpdated: ((Identifier<Section>) -> ())? = nil, itemUpdated: ((Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ())? = nil) {
        super.init(id: id, sectionUpdated: sectionUpdated, itemUpdated: itemUpdated)
        items = [DefaultDetailsTableViewCellModel(title: "Temperature", value: "-")]
    }
    
    override func update(with characteristic: HealthTermometerCharacteristic) {
        let formatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        formatter.numberFormatter = numberFormatter
        
        items[0].details = formatter.string(from: characteristic.temperature)
        
        super.update(with: characteristic)
    }
    
    override var sectionTitle: String {
        return "Temperature"
    }
}
