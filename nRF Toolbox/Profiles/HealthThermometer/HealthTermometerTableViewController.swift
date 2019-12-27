//
//  HealthTermometerTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

private extension Identifier where Value == Section {
    static let temperature: Identifier<Section> = "temperature"
    static let additionalInfo: Identifier<Section> = "additionalInfo"
}

class HealthTermometerTableViewController: PeripheralTableViewController {
    private var temperatureSection = HealthTemperatureSection(id: .temperature)
    private var additionalInfoSection = HealthTemperatureAditionalSection(id: .additionalInfo)
    
    override var peripheralDescription: PeripheralDescription { .healthTemperature }
    override var internalSections: [Section] { [temperatureSection, additionalInfoSection] }
    override var navigationTitle: String { "Health Thermometer" }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.HealthTemperature.measurement:
            let temperature = HealthTermometerCharacteristic(data: characteristic.value!)
            temperatureSection.update(with: temperature)
            additionalInfoSection.update(with: temperature)
            tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}
