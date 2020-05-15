/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
        chartSection.reset()
        tableView.reloadData()
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
        tableView.register(LinearChartTableViewCell.self, forCellReuseIdentifier: "LinearChartTableViewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.registerCellNib(cell: StepperTableViewCell.self)
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
            do {
                sessionStartTime = try SessionStartTime(data: characteristic.value!)
            } catch let error {
                displayErrorAlert(error: error)
            }
        case .measurement:
            let data = characteristic.value!
            #if RAND
            let value = ContinuousGlucoseMonitorMeasurement(value: Float(randomizer.next()!))
            #else
            let value = ContinuousGlucoseMonitorMeasurement(data: data, sessionStartTime: sessionStartTime)
            #endif

            lastValueSection.update(with: value)
            chartSection.update(with: value)
            tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
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
