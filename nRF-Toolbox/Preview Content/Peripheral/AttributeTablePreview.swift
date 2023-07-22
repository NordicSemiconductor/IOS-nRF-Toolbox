//
//  AttributeTablePreview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 20/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetoothMock
import iOS_Bluetooth_Numbers_Database

extension AttributeTable {
    static var preview: AttributeTable {
        var at = AttributeTable()
        
        let genericAccess = CBMServiceMock(
            type: CBMUUID(string: S.GenericAccess.genericAccess.uuidString),
            primary: true,
            includedService: nil,
            characteristics: nil
        )
        
        let genericAttribute = CBMServiceMock(
            type: CBMUUID(string: S.GenericAttribute.genericAttribute.uuidString),
            primary: true,
            includedService: nil,
            characteristics: nil
        )
        
        let clientCharacteristicConfiguration = CBMDescriptorMock(type: CBMUUID(string: D.Gatt.ClientCharacteristicConfiguration.clientCharacteristicConfiguration.uuidString))
        
        let rscMeasurement = CBMCharacteristicMock(
            type: CBMUUID(string: C.RscMeasurement.rscMeasurement.uuidString),
            properties: .notify,
            descriptors: clientCharacteristicConfiguration
        )
        
        let rscFeature = CBMCharacteristicMock(
            type: CBMUUID(string: C.RscFeature.rscFeature.uuidString),
            properties: .read
        )
        
        let scControlPoint = CBMCharacteristicMock(
            type: CBMUUID(string: C.ScControlPoint.scControlPoint.uuidString),
            properties: [.write, .indicate],
            descriptors: clientCharacteristicConfiguration
        )
        
        let sensorLocation = CBMCharacteristicMock(
            type: CBMUUID(string: C.SensorLocation.sensorLocation.uuidString),
            properties: .read
        )
        
        let runningSpeedAndCadence = CBMServiceMock(
            type: CBMUUID(string: S.RunningSpeedAndCadence.runningSpeedAndCadence.uuidString),
            primary: true,
            characteristics: rscMeasurement, rscFeature, scControlPoint, sensorLocation
        )
        
        at.addService(genericAccess)
        at.addService(genericAttribute)
        at.addService(runningSpeedAndCadence)
        
        return at
        
    }
}
