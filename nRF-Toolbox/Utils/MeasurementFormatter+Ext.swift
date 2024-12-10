//
//  MeasurementFormatter+Ext.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 10/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension MeasurementFormatter {
    
    static func numeric(maximumFractionDigits: Int = 1, minimumIntegerDigits: Int = 1) -> MeasurementFormatter {
        let measurementFormatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        numberFormatter.minimumIntegerDigits = minimumIntegerDigits
        measurementFormatter.numberFormatter = numberFormatter
        return measurementFormatter
    }
}
