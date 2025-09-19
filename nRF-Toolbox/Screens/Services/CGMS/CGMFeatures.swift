//
//  CGMFeatures.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 19/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

struct CGMFeatures {
    let calibrationSupported: Bool
    let patientHighLowAlertsSupported: Bool
    let hypoAlertsSupported: Bool
    let hyperAlertsSupported: Bool
    let rateOfIncreaseDecreaseAlertsSupported: Bool
    let deviceSpecificAlertSupported: Bool
    let sensorMalfunctionDetectionSupported: Bool
    let sensorTempHighLowDetectionSupported: Bool
    let sensorResultHighLowSupported: Bool
    let lowBatteryDetectionSupported: Bool
    let sensorTypeErrorDetectionSupported: Bool
    let generalDeviceFaultSupported: Bool
    let e2eCrcSupported: Bool
    let multipleBondSupported: Bool
    let multipleSessionsSupported: Bool
    let cgmTrendInfoSupported: Bool
    let cgmQualityInfoSupported: Bool

    init(value: Int) {
        calibrationSupported = (value & 0x000001) != 0
        patientHighLowAlertsSupported = (value & 0x000002) != 0
        hypoAlertsSupported = (value & 0x000004) != 0
        hyperAlertsSupported = (value & 0x000008) != 0
        rateOfIncreaseDecreaseAlertsSupported = (value & 0x000010) != 0
        deviceSpecificAlertSupported = (value & 0x000020) != 0
        sensorMalfunctionDetectionSupported = (value & 0x000040) != 0
        sensorTempHighLowDetectionSupported = (value & 0x000080) != 0
        sensorResultHighLowSupported = (value & 0x000100) != 0
        lowBatteryDetectionSupported = (value & 0x000200) != 0
        sensorTypeErrorDetectionSupported = (value & 0x000400) != 0
        generalDeviceFaultSupported = (value & 0x000800) != 0
        e2eCrcSupported = (value & 0x001000) != 0
        multipleBondSupported = (value & 0x002000) != 0
        multipleSessionsSupported = (value & 0x004000) != 0
        cgmTrendInfoSupported = (value & 0x008000) != 0
        cgmQualityInfoSupported = (value & 0x010000) != 0
    }
}
