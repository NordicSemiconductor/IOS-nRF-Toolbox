//
// Created by Nick Kibysh on 22/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct SensorStatusAnnunciation {
    init(data: Data) {

    }
}

struct ContinuousGlucoseMonitorMeasurement {
    //TODO: Remove var. Set let
    var glucoseConcentration: Float
    let date: Date?
    /*
    let sensorStatusAnnunciation: SensorStatusAnnunciation
    let quality: Float
    let e2eCrc: Int
    */
    init(data: Data, sessionStartTime: SessionStartTime) {
        glucoseConcentration = data.readSFloat(from: 2)
        date = Date()
    }
}