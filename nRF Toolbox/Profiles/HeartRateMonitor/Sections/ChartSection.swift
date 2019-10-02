//
//  GlucoseChartSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CorePlot

struct ChartSection: Section {
    private var heartRateValues: [(TimeInterval, Int)] = []
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: LinearChartTableViewCell.self)
        cell.update(with: heartRateValues.map { ($0.0, Double($0.1)) } )
        return cell
    }
    
    func reset() { }
    
    let numberOfItems: Int = 1
    let isHidden: Bool = false
    let sectionTitle: String = "Heart Rate"
    
    let id: Identifier<Section>
    init(id: Identifier<Section>) {
        self.id = id 
    }
    
    mutating func update(with data: HeartRateMeasurementCharacteristic) {
        let lastOne = heartRateValues.last?.1 ?? 100
        let delta = Int.random(in: -2...2)
        
        var newValue = lastOne + delta
        newValue = max(60, newValue)
        newValue = min(140, newValue)
        // data.heartRate
        heartRateValues.append((Date().timeIntervalSince1970, newValue))
    }
    
}
