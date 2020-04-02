//
//  StrideSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class ActivitySection: DetailsTableViewSection<RunningCharacteristic> {
    override var sectionTitle: String { "Activity type" } 
    
    override func update(with characteristic: RunningCharacteristic) {
        items = [DefaultDetailsTableViewCellModel(title: "Activity", value: characteristic.isRunning ? "Running" : "Walking")]
        super.update(with: characteristic)
    }
}
