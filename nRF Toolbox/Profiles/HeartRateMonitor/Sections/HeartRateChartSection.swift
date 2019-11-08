//
//  ContinuousGlucoseChartData.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CorePlot

class HeartRateChartSection: ChartDataSection<HeartRateMeasurementCharacteristic> {
    override var sectionTitle: String { "Heart Rate" }

    override func transform(_ item: HeartRateMeasurementCharacteristic) -> (x: Double, y: Double) {
        (x: item.date.timeIntervalSince1970, y: Double(item.heartRate))
    }
}
