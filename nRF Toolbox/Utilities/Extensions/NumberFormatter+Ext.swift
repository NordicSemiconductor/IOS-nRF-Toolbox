//
// Created by Nick Kibish on 24.04.2020.
// Copyright (c) 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension NumberFormatter {
    static var zeroDecimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfEven
        return formatter
    }
}