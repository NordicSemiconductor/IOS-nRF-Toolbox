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

class GlucoseMonitorViewController: PeripheralTableViewController {
    private var bgmSection = BGMSection()
    private var recordAccessControlPoint: CBCharacteristic?
    
    private lazy var actionSection: BGMActionSection = { [unowned self] in
        let section = BGMActionSection()
        section.registerRequiredCells(for: self.tableView)
        section.refreshAction = { id in
            self.updateDisplayedItems(id)
        }
        
        section.clearAction = {
            self.bgmSection.clearReadings()
            self.tableView.reloadData()
        }
        
        section.deleteAllAction = {
            self.bgmSection.clearReadings()
            let data = Data([BGMOpCode.deleteStoredRecords.rawValue, BGMOperator.allRecords.rawValue])
            self.activePeripheral?.writeValue(data, for: self.recordAccessControlPoint!, type: .withResponse)
        }
        return section
    }()
    
    private var selectionSection = OptionSelectionSection<GlucoseMonitorViewController>(id: .selectionResult, sectionTitle: "", items: [OptionSelectionSection.Item(option: "Display Items", selectedCase: "All")])
    
    override var navigationTitle: String { "Glucose" }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellNib(cell: BGMTableViewCell.self)
    }
    
    // MARK: Table View Handlers
    override func selected(item: Int, in section: Section) {
        switch section.id {
        case .selectionResult:
            handleOptionSelection()
        case .bgMActionSection:
            actionSection.didSelectRaw(at: item)
        default:
            super.selected(item: item, in: section)
        }
    }
    
    override var internalSections: [Section] { [actionSection, bgmSection] }
    
    override var peripheralDescription: PeripheralDescription { .bloodGlucoseMonitor }
    
    override func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        super.didDiscover(characteristic: characteristic, for: service, peripheral: peripheral)
        if characteristic.uuid == CBUUID.Characteristics.BloodGlucoseMonitor.recordAccessControlPoint {
            recordAccessControlPoint = characteristic
            updateDisplayedItems(.all)
        }
    }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        let array = UnsafeMutablePointer<UInt8>(OpaquePointer(((characteristic.value as NSData?)?.bytes)!))
        
        switch characteristic.uuid {
        case CBUUID.Characteristics.BloodGlucoseMonitor.glucoseMeasurement:
            let reading = GlucoseReading(array)
            bgmSection.update(reading: reading)
            tableView.reloadData()
        case CBUUID.Characteristics.BloodGlucoseMonitor.glucoseMeasurementContext:
            let context = GlucoseReadingContext(array)
            bgmSection.update(context: context)
            tableView.reloadData()
        case CBUUID.Characteristics.BloodGlucoseMonitor.recordAccessControlPoint:
            handleAccessControlPoint(array: array)
            tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}

extension GlucoseMonitorViewController {
    private func handleAccessControlPoint(array: UnsafeMutablePointer<UInt8>) {
        let responseCode = BGMResponseCode(rawValue:array[2])!
        switch responseCode {
        case .success:
            reloadSection(id: .bgmReadings)
        default:
            guard let error = responseCode.error else {
                SystemLog(category: .ble, type: .error).log(message: "Cannot parse error for \(responseCode)")
                return
            }
            SystemLog(category: .ble, type: .error).log(message: "Error access control error: \(error.localizedDescription)")
            AppUtilities.showAlert(title: error.title, andMessage: error.message ?? "", from: self)
        }
    }
    
    private func handleOptionSelection() {
        let cases = Identifier<GlucoseMonitorViewController>.allCases
        
        let selector = SelectionsTableViewController(items: cases, selectedItem: 0) { item in
            let selected = cases[item]
            self.selectionSection.items[0].selectedCase = selected
            self.reloadSection(id: .selectionResult)
            self.updateDisplayedItems(selected)
        }
        selector.navigationItem.title = selectionSection.items.first?.option
        
        navigationController?.pushViewController(selector, animated: true)
    }
    
    private func updateDisplayedItems(_ itemsToDisplay: Identifier<GlucoseMonitorViewController>) {
        bgmSection.clearReadings()
        
        let bgmOperator: UInt8 = {
            switch itemsToDisplay {
            case .all: return BGMOperator.allRecords.rawValue
            case .first: return BGMOperator.first.rawValue
            case .last: return BGMOperator.last.rawValue
            default: return 0
            }
        }()
        
        let data = Data([BGMOpCode.reportStoredRecords.rawValue, bgmOperator])
        activePeripheral?.writeValue(data, for: recordAccessControlPoint!, type: .withResponse)
    }
}
