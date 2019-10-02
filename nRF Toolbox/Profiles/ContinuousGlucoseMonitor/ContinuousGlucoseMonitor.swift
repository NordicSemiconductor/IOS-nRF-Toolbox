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
    private var chartSection = LinearChartSection(id: .linearChartSection)
    private lazy var timeSliderSection = TimeSliderSection(id: .timeSliderSection) { [unowned self] ti in
        var accessParam: [UInt8] = [CGMOpCode.setCommunicationInterval.rawValue, UInt8(ti)]
        let data = Data(bytes: &accessParam, count: 2)
        self.activePeripheral?.writeValue(data, for: self.specificOpsControlPointCharacteristic!, type: .withResponse)
    }

    private func reset() {
        self.chartSection.reset()
        self.lastValueSection.isHidden = true
        self.tableView.reloadData()
    }

    private lazy var startStopSection = StartStopSection(startAction: {
        let data = Data([CGMOpCode.startSession.rawValue])
        self.activePeripheral?.writeValue(data, for: self.specificOpsControlPointCharacteristic!, type:.withResponse)
        self.reset()
    }, stopAction: {
        let data = Data([CGMOpCode.stopStopSession.rawValue])
        self.activePeripheral?.writeValue(data, for: self.specificOpsControlPointCharacteristic!, type:.withResponse)
    }, id: .startStopSection)

    private var sessionStartTime = SessionStartTime(date: Date())
    private var randomizer = RandomValueSequence(top: 6.1, bottom: 4.4, value: 5.0, delta: 0.2)

    override var internalSections: [Section] {
        [lastValueSection, chartSection, timeSliderSection, startStopSection]
    }
    override var peripheralDescription: Peripheral { .continuousGlucoseMonitor }
    override var navigationTitle: String { "Continuous Glucose Monitor" }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(LinearChartTableViewCell.self, forCellReuseIdentifier: "LinearChartTableViewCell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(cell: SliderTableViewCell.self)
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
            var value = ContinuousGlucoseMonitorMeasurement(data: data, sessionStartTime: sessionStartTime)
            value.glucoseConcentration = Float(randomizer.next()!)
            self.lastValueSection.update(with: value)
            self.chartSection.update(with: value)
            self.tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}

extension ContinuousGlucoseMonitor {
    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.visibleSections[indexPath.section] is LinearChartSection, indexPath.row == 0 {
            return 300
        } else if self.visibleSections[indexPath.section] is TimeSliderSection, indexPath.row == 0 {
            return 52
        }
        return 44
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = visibleSections[indexPath.section]

        if section is StartStopSection {
            startStopSection.toggle()
            tableView.reloadData()
        } else if section is LinearChartSection, indexPath.row == 1 {
            let listController = GlucoseValueList(items: chartSection.items)
            navigationController?.pushViewController(listController, animated: true)
        } else {
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
}
