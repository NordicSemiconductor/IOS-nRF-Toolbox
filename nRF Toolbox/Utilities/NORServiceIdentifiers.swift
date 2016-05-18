//
//  NORServiceIdentifiers.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 18/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

class NORServiceIdentifiers: NSObject {
    static let bgmServiceUUIDString                                 = "00001808-0000-1000-8000-00805F9B34FB"
    static let bgmGlucoseMeasurementCharacteristicUUIDString        = "00002A18-0000-1000-8000-00805F9B34FB"
    static let bgmGlucoseMeasurementContextCharacteristicUUIDString = "00002A34-0000-1000-8000-00805F9B34FB"
    static let bgmRecordAccessControlPointCharacteristicUUIDString  = "00002A52-0000-1000-8000-00805F9B34FB"
    
    static let bpmServiceUUIDString                                 = "00001810-0000-1000-8000-00805F9B34FB"
    static let bpmBloodPressureMeasurementCharacteristicUUIDString  = "00002A35-0000-1000-8000-00805F9B34FB"
    static let bpmIntermediateCuffPressureCharacteristicUUIDString  = "00002A36-0000-1000-8000-00805F9B34FB"
    
    static let cscServiceUUIDString                                 = "00001816-0000-1000-8000-00805F9B34FB"
    static let cscMeasurementCharacteristicUUIDString               = "00002A5B-0000-1000-8000-00805F9B34FB"
    
    static let rscServiceUUIDString                                 = "00001814-0000-1000-8000-00805F9B34FB"
    static let rscMeasurementCharacteristicUUIDString               = "00002A53-0000-1000-8000-00805F9B34FB"
    
    static let hrsServiceUUIDString                                 = "0000180D-0000-1000-8000-00805F9B34FB"
    static let hrsHeartRateCharacteristicUUIDString                 = "00002A37-0000-1000-8000-00805F9B34FB"
    static let hrsSensorLocationCharacteristicUUIDString            = "00002A38-0000-1000-8000-00805F9B34FB"
    
    static let htsServiceUUIDString                                 = "00001809-0000-1000-8000-00805F9B34FB"
    static let htsMeasurementCharacteristicUUIDString               = "00002A1C-0000-1000-8000-00805F9B34FB"
    
    static let proximityImmediateAlertServiceUUIDString             = "00001802-0000-1000-8000-00805F9B34FB"
    static let proximityLinkLossServiceUUIDString                   = "00001803-0000-1000-8000-00805F9B34FB"
    static let proximityAlertLevelCharacteristicUUIDString          = "00002A06-0000-1000-8000-00805F9B34FB"
    
    static let batteryServiceUUIDString                             = "0000180F-0000-1000-8000-00805F9B34FB"
    static let batteryLevelCharacteristicUUIDString                 = "00002A19-0000-1000-8000-00805F9B34FB"
    
    static let uartServiceUUIDString                                = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    static let uartTXCharacteristicUUIDString                       = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    static let uartRXCharacteristicUUIDString                       = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
}
