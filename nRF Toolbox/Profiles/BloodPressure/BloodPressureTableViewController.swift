//
//  BloodPressureTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

extension Identifier where Value == Section {
    static let bloodPressure: Identifier<Section> = "bloodPressure"
    static let cuffPressure: Identifier<Section> = "cuffPressure"
    static let dateTime: Identifier<Section> = "TimeBloodPressureSection"
    static let heartRate: Identifier<Section> = "HeartRate"
}

class BloodPressureTableViewController: PeripheralTableViewController {
    private var bloodPressureSection = BloodPressureSection(id: .bloodPressure)
    private var cuffPressureSection = CuffPressureSection(id: .cuffPressure)
    private var dateTimeSection = TimeBloodPressureSection(id: .dateTime)
    private var heartRateSection = PulseBloodPressureSection(id: .heartRate)
    
    override var internalSections: [Section] { [bloodPressureSection, heartRateSection, dateTimeSection, cuffPressureSection] }
    override var peripheralDescription: PeripheralDescription { .bloodPressure }
    
    private var dataSectionIds: [Identifier<Section>] = [.bloodPressure, .cuffPressure]
    override var navigationTitle: String { "Blood Pressure" }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        guard let value = characteristic.value else {
            super.didUpdateValue(for: characteristic)
            return
        }
        switch characteristic.uuid {
        case CBUUID.Characteristics.BloodPressure.measurement:
            let bloodPressureCharacteristic = BloodPreasureCharacteristic(data: value)

            bloodPressureSection.update(with: bloodPressureCharacteristic)
            heartRateSection.update(with: bloodPressureCharacteristic)
            dateTimeSection.update(with: bloodPressureCharacteristic)

            tableView.reloadData()
        case CBUUID.Characteristics.BloodPressure.intermediateCuff:
            cuffPressureSection.update(with: CuffPreasureCharacteristic(data: value))

            tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }

}
