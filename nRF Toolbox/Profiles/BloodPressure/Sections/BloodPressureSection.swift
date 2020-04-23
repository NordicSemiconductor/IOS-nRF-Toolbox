//
//  BloodPressureSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class BloodPressureSection: DetailsTableViewSection<BloodPressureCharacteristic> {
    
    override init(id: Identifier<Section>, sectionUpdated: ((Identifier<Section>) -> ())? = nil, itemUpdated: ((Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ())? = nil) {
        super.init(id: id, sectionUpdated: sectionUpdated, itemUpdated: itemUpdated)
    }
    
    override var sectionTitle: String { "Blood Pressure" }
    
    override func reset() {
        items = [
            DefaultDetailsTableViewCellModel(title: "Systolic", value: "-"),
            DefaultDetailsTableViewCellModel(title: "Diastolic", value: "-"),
            DefaultDetailsTableViewCellModel(title: "Mean AP", value: "-")
        ]
    }
    
    override func update(with characteristic: BloodPressureCharacteristic) {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        
        let systolicItem = DefaultDetailsTableViewCellModel(title: "Systolic", value: formatter.string(from: characteristic.systolicPressure))
        let diastolicItem = DefaultDetailsTableViewCellModel(title: "Diastolic", value: formatter.string(from: characteristic.diastolicPressure))
        let maItem = DefaultDetailsTableViewCellModel(title: "Mean AP", value: formatter.string(from: characteristic.meanArterialPressure))
        
        items = [systolicItem, diastolicItem, maItem]
    }
}
