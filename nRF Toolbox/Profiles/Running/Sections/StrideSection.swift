//
//  StrideSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class ActivitySection: DetailsTableViewSection {
    override var sectionTitle: String { "Activity type" } 
    
    override func update(with data: Data) {
        let runningData = RunningCharacteristic(data: data)
        self.items = [DefaultDetailsTableViewCellModel(title: "Activity", value: runningData.isRunning ? "Running" : "Walking")]
        super.update(with: data)
    }
}
