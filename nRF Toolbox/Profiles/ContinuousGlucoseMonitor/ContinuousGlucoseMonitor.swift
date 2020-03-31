//
// Created by Nick Kibysh on 21/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

private extension Identifier where Value == Section {
    static let lastGlucoseValue: Identifier<Section> = "LastGlucoseValue"
    static let linearChartSection: Identifier<Section> = "LinearChartSection"
    static let timeSliderSection: Identifier<Section> = "TimeSliderSection"
    static let startStopSection: Identifier<Section> = "StartStopSection"
}

private extension CBUUID {
    static let feature = CBUUID(hex: 0x2AA8)
    static let measurement = CBUUID(hex: 0x2AA7)
    static let sessionRunTime = CBUUID(hex: 0x2AAB)
    static let sessionStartTime = CBUUID(hex: 0x2AAA)
    static let specificOpsControlPoint = CBUUID(hex: 0x2AAC)
    static let status = CBUUID(hex: 0x2AA9)
    static let measurementContext = CBUUID(hex: 0x2A34)
    static let recordAccessPoint = CBUUID(hex: 0x2A52)
}

class ContinuousGlucoseMonitor: PeripheralTableViewController {
    // MARK: Characteristics
    private var specificOpsControlPointCharacteristic: CBCharacteristic?
    private var sessionStartTimeCharacteristic: CBCharacteristic?

    // MARK: Sections
    private var lastValueSection = LastGlucoseValueSection(id: .lastGlucoseValue)
    private var chartSection = ContinuousGlucoseChartData(id: .linearChartSection)
    private lazy var timeIntervalSection = TimeIntervalSection(id: .timeSliderSection) { [unowned self] ti in
        var accessParam: [UInt8] = [CGMOpCode.setCommunicationInterval.rawValue, UInt8(ti)]
        let data = Data(bytes: &accessParam, count: 2)
        self.activePeripheral?.writeValue(data, for: self.specificOpsControlPointCharacteristic!, type: .withResponse)
    }

    private func reset() {
        self.chartSection.reset()
        self.lastValueSection.isHidden = true
        self.tableView.reloadData()
    }

    private lazy var startStopSection = StartStopSection(startAction: { [unowned self] in
        let data = Data([CGMOpCode.startSession.rawValue])
        self.activePeripheral?.writeValue(data, for: self.specificOpsControlPointCharacteristic!, type:.withResponse)
        self.reset()
    }, stopAction: { [unowned self] in
        let data = Data([CGMOpCode.stopStopSession.rawValue])
        self.activePeripheral?.writeValue(data, for: self.specificOpsControlPointCharacteristic!, type:.withResponse)
    }, id: .startStopSection)

    private var sessionStartTime = SessionStartTime(date: Date())
    #if RAND
    private var randomizer = Randomizer(top: 6.1, bottom: 4.4, value: 5.0, delta: 0.2)
    #endif

    override var internalSections: [Section] {
        [lastValueSection, chartSection, timeIntervalSection, startStopSection]
    }
    override var peripheralDescription: PeripheralDescription { .continuousGlucoseMonitor }
    override var navigationTitle: String { "Continuous Glucose" }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(LinearChartTableViewCell.self, forCellReuseIdentifier: "LinearChartTableViewCell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.registerCellNib(cell: StepperTableViewCell.self)
    }

    override func didDiscover(characteristic: CoreBluetooth.CBCharacteristic, for service: CoreBluetooth.CBService, peripheral: CoreBluetooth.CBPeripheral) {
        switch characteristic.uuid {
        case .specificOpsControlPoint:
            specificOpsControlPointCharacteristic = characteristic
            let data = Data([CGMOpCode.startSession.rawValue])
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        case .sessionStartTime:
            sessionStartTimeCharacteristic = characteristic
        default:
            break
        }
        super.didDiscover(characteristic: characteristic, for: service, peripheral: peripheral)
    }

    override func statusDidChanged(_ status: PeripheralStatus) {
        if case .disconnected = status {
            specificOpsControlPointCharacteristic = nil
            sessionStartTimeCharacteristic = nil
        }
        super.statusDidChanged(status)
    }

    override func didUpdateValue(for characteristic: CoreBluetooth.CBCharacteristic) {
        switch characteristic.uuid {
        case .sessionStartTime:
            sessionStartTime = SessionStartTime(data: characteristic.value!)
        case .measurement:
            let data = characteristic.value!
            #if RAND
            let value = ContinuousGlucoseMonitorMeasurement(value: Float(randomizer.next()!))
            #else
            let value = ContinuousGlucoseMonitorMeasurement(data: data, sessionStartTime: sessionStartTime)
            #endif

            self.lastValueSection.update(with: value)
            self.chartSection.update(with: value)
            self.tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch visibleSections[indexPath.section] {
        case is StartStopSection:
            startStopSection.toggle()
            tableView.reloadData()
        case is ContinuousGlucoseChartData where indexPath.row == 1:
            let listController = GlucoseValueList(items: chartSection.items)
            navigationController?.pushViewController(listController, animated: true)
        default:
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
}
