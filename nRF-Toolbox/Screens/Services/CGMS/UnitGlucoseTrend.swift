//
//  UnitGlucoseTrend.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 08/10/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - UnitGlucoseTrend

final class UnitGlucoseTrend: Dimension, @unchecked Sendable {
    static let milligramsPerDecilitrePerMinute = UnitGlucoseTrend(
        symbol: "mg/dL/min",
        converter: UnitConverterLinear(coefficient: 1.0)
    )

    override class func baseUnit() -> UnitGlucoseTrend {
        return .milligramsPerDecilitrePerMinute
    }
}
