//
//  HeartRateMonitorTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

private extension Identifier where Value == Section {
    static let sensorLocation: Identifier<Section> = "SensorLocation"
    static let heartRateValue: Identifier<Section> = "HeartRateValue"
    static let heartRateChart: Identifier<Section> = "HeartRateChart"
    static let chartSection: Identifier<Section> = "ChartSection"
}

class HeartRateMonitorTableViewController: PeripheralTableViewController {
    private let locationSection = SernsorLocationSection(id: .sensorLocation)
    private let instantaneousHeartRateSection = HeartRateSection(id: .heartRateValue)
    private var chartSection = HeartRateChartSection(id: .chartSection)

    #if RAND
    var randomizer = Randomizer(top: 120, bottom: 60, value: 80, delta: 2)
    #endif
    
    override var peripheralDescription: PeripheralDescription { .heartRateSensor }
    override var navigationTitle: String { "Heart Rate" }
    override var internalSections: [Section] { [instantaneousHeartRateSection, locationSection, chartSection] }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(LinearChartTableViewCell.self, forCellReuseIdentifier: "LinearChartTableViewCell")
    }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.HeartRate.measurement:
            #if RAND
            let data = HeartRateMeasurementCharacteristic(value: randomizer.next()!)
            #else
            let data = HeartRateMeasurementCharacteristic(with: characteristic.value!, date: Date())
            #endif
            instantaneousHeartRateSection.update(with: data)
            chartSection.update(with: data)
            tableView.reloadData()
        case CBUUID.Characteristics.HeartRate.location:
            BodySensorLocationCharacteristic(with: characteristic.value!)
                .map { self.locationSection.update(with: $0) }
            tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}
