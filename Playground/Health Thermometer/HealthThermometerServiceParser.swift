//
//  HealthThermometerServiceParser.swift
//  Playground
//
//  Created by Nick Kibysh on 03/03/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreBluetooth
import iOS_Bluetooth_Numbers_Database

/*

Temperature Measurement | M | Indicate | None.
Client Characteristic Configuration descriptor | M | Read, Write | None.
Temperature Type | O | Read | None.
Intermediate Temperature | O | Notify | None.
Client Characteristic Configuration descriptor | C.1 | Read, Write | None.
Measurement Interval | O | Read | Indicate, Write | Read: None. Writable with authentication.
Client Characteristic Configuration descriptor | C.2 | Read, Write | None.
Valid Range descriptor | C.3 | Read | None.

*/

struct HealthThermometerServiceParser {
    let htService: CBService

    let temperatureMeasurementCharacteristic: CBCharacteristic
    let temperatureMeasurementDescriptor: CBDescriptor

    let temperatureTypeCharacteristic: CBCharacteristic?

    let intermediateTemperatureCharacteristic: CBCharacteristic?
    let intermediateTemperatureDescriptor: CBDescriptor?

    let measurementIntervalCharacteristic: CBCharacteristic?
    let measurementIntervalDescriptor: CBDescriptor?

    let validRangeDescriptor: CBDescriptor?

    init(htService: CBService) {
        assert(htService.uuid == Service.healthThermometer.uuid, "Health Thermometer Service is expected")
        self.htService = htService

        temperatureMeasurementCharacteristic = htService.characteristics!.first(where: { $0.uuid == Characteristic.temperatureMeasurement.uuid })!
        temperatureMeasurementDescriptor = temperatureMeasurementCharacteristic.descriptors!.first(where: { $0.uuid == Descriptor.gattClientCharacteristicConfiguration.uuid })!

        temperatureTypeCharacteristic = htService.characteristics?.first(where: { $0.uuid == Characteristic.temperatureType.uuid })

        intermediateTemperatureCharacteristic = htService.characteristics?.first(where: { $0.uuid == Characteristic.intermediateTemperature.uuid })
        intermediateTemperatureDescriptor = intermediateTemperatureCharacteristic?.descriptors?.first(where: { $0.uuid == Descriptor.gattClientCharacteristicConfiguration.uuid })

        measurementIntervalCharacteristic = htService.characteristics?.first(where: { $0.uuid == Characteristic.measurementInterval.uuid })
        measurementIntervalDescriptor = measurementIntervalCharacteristic?.descriptors?.first(where: { $0.uuid == Descriptor.gattClientCharacteristicConfiguration.uuid })

        validRangeDescriptor = htService.characteristics?.first(where: { $0.uuid == Characteristic.descriptorValueChanged.uuid })?.descriptors?.first(where: { $0.uuid == Descriptor.validRange.uuid })
    }
}
