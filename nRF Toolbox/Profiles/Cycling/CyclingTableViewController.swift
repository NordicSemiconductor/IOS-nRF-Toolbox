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

class CyclingTableViewController: PeripheralTableViewController {
    private var cyclingSection = CyclingTableViewSection()
    private var wheelSizeSection = WheelSizeSection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "DetailsTableViewCell")
        navigationItem.title = "Cycling Speed and Cadence"

        wheelSizeSection.wheelSizeChangedAction = {
            self.cyclingSection.wheelSize = $0.converted(to: .meters).value
        }

        cyclingSection.wheelSize = wheelSizeSection.wheelSize.converted(to: .meters).value
    }
    
    override var internalSections: [Section] { [wheelSizeSection, cyclingSection] }
    override var peripheralDescription: PeripheralDescription { .cyclingSpeedCadenceSensor }

    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.CyclingSesnor.measurement:
            guard let value = characteristic.value else {
                fallthrough
            }
            handleCycling(value: value)
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
    
    private func handleCycling(value: Data) {
        cyclingSection.update(with: value)
        tableView.reloadData()
    }
}


