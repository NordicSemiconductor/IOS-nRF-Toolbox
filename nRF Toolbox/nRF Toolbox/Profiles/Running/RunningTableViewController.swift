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
    static let runningSpeedCadence: Identifier<Section> = "runningSpeedCadence"
    static let runningActivitySection: Identifier<Section> = "runningActivitySection"
}

class RunningTableViewController: PeripheralTableViewController {
    lazy private var runningSpeedCadenceSection = RunningSpeedSection.init(id: .runningSpeedCadence, itemUpdated: { [weak self] (section, item) in
            self?.reloadItemInSection(section, itemId: item, animation: .none)
        })
    private let activitySection = ActivitySection(id: .runningActivitySection)
    override var peripheralDescription: PeripheralDescription { .runningSpeedCadenceSensor }
    override var internalSections: [Section] { [activitySection, runningSpeedCadenceSection] }
    override var navigationTitle: String { "Running Speed and Cadence" }
    
    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.Running.measurement:
            guard let value = characteristic.value else { return }
            do {
                let running = try RunningCharacteristic(data: value)
                runningSpeedCadenceSection.update(with: running)
                activitySection.update(with: running)
                
                tableView.reloadData()
            } catch let error {
                displayErrorAlert(error: error)
            }
            
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
}
