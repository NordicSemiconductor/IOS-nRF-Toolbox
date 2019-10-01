//
//  RunningSpeedCadenceSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension Identifier where Value == DetailsTableViewCellModel {
    static let numberOfSteps: Identifier<DetailsTableViewCellModel> = "NumberOfSteps"
}

class RunningSpeedSection: DetailsTableViewSection {
    
    private var numberOfSteps: Int = 0
    private var startDate: Date = Date()
    private var timer: Timer?
    
    override var sectionTitle: String { "Speed and Cadence" }
    
    override func reset() {
        timer?.invalidate()
        numberOfSteps = 0
        super.reset()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    override func update(with data: Data) {
        let runningData = RunningCharacteristic(data: data)
        let cadence = runningData.instantaneousCadence
        var items: [DefaultDetailsTableViewCellModel] = [
            DefaultDetailsTableViewCellModel(title: "Pace", value: PaceMeasurementFormatter().paceString(from: runningData.instantaneousSpeed)),
            DefaultDetailsTableViewCellModel(title: "Cadence", value: "\(cadence)")
        ]
        
        if let distance = runningData.totalDistance, let strideLength = runningData.instantaneousStrideLength {
            items += [
                DefaultDetailsTableViewCellModel(title: "Total Distance", value: MeasurementFormatter().string(from: distance)),
                DefaultDetailsTableViewCellModel(title: "Stride Length", value: MeasurementFormatter().string(from: strideLength))
            ]
        }
        
        items.append(DefaultDetailsTableViewCellModel(title: "Number of Steps", value: "\(numberOfSteps)", identifier: .numberOfSteps))
        
        self.items = items
        super.update(with: data)
        
        self.timer?.invalidate()
        if cadence > 0 {
            self.timer = Timer.scheduledTimer(withTimeInterval: 60.0 / Double(cadence), repeats: true) { [weak self] (timer) in
                guard let `self` = self else { return }
                self.numberOfSteps += 1
                
                self.items
                    .firstIndex(where: { $0.identifier == .numberOfSteps })
                    .map {
                        var item = self.items[$0] as! DefaultDetailsTableViewCellModel
                        item.value = "\(self.numberOfSteps)"
                        self.items[$0] = item
                    }
                
                self.itemUpdated?(self.id, .numberOfSteps)
            }
        }
    }
    
    
    
}
