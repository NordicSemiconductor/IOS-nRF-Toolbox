//
//  PaceMeasurementFormatter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

class PaceMeasurementFormatter: MeasurementFormatter {
    func paceString(from measurement: Measurement<UnitSpeed>) -> String {
        let distanceUnit: UnitLength = locale.usesMetricSystem ? .kilometers : .miles
        let metersInUnit = Measurement<UnitLength>(value: 1, unit: distanceUnit).converted(to: .meters).value
        
        let mpsValue = measurement.converted(to: .metersPerSecond).value
        let paceValue = 1 / (mpsValue / metersInUnit)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        let timeStr = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: paceValue))
        
        return "\(timeStr) min/\(distanceUnit.symbol)"
    }
}
