//
//  CuffPressureSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class CuffPressureSection: DetailsTableViewSection<CuffPreasureCharacteristic> {
    
    override var sectionTitle: String { "Cuff Pressure" }
    
    override func update(with characteristic: CuffPreasureCharacteristic) {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        
        items = [DefaultDetailsTableViewCellModel(title: "Intermediate Cuff Pressure", value: formatter.string(from: characteristic.cuffPreasure))]
    }
}
