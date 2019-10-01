//
//  MeasurementFormatter+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 23/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
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
