//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct ContinuousGlucoseMonitorMeasurement {
    let glucoseConcentration: Float
    let date: Date?

    init(data: Data, sessionStartTime: SessionStartTime) {
        glucoseConcentration = data.readSFloat(from: 2)
        let timeOffset: UInt16 = data.read(fromOffset: 4)
        let sessionTime = sessionStartTime.date
        date = sessionTime.addingTimeInterval(Double(timeOffset * 60))
    }

    #if DEBUG
    init(value: Float) {
        glucoseConcentration = value
        date = Date()
    }
    #endif
}