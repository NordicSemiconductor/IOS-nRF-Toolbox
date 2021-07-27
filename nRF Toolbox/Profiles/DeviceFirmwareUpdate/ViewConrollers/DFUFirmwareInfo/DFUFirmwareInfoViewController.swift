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
import NordicDFU

class DFUFirmwareInfoViewController: UITableViewController, AlertPresenter {

    let router: DFURouterType
    private var firmware: DFUFirmware
    let bluetoothManager: PeripheralHolder
    private let documentPicker = DFUDocumentPicker()
    private lazy var sections: [DFUActionSection] = [deviceInfoSection, firmwareInfoSection, updateSection]
    
    private lazy var deviceInfoSection = DFUDeviceInfoSection(peripheral: bluetoothManager.peripheral) { [unowned self] in
        self.router.goToBluetoothConnector(scanner: PeripheralScanner(services: []), presentationType: .present) { (p) in
            self.presentedViewController?.dismsiss()
            (self.sections[0] as? DFUDeviceInfoSection)?.peripheral = p
            self.tableView.reloadSections([0], with: .none)
        }
    }
    
    private lazy var firmwareInfoSection = DFUFirmwareSizeSection(firmware: firmware) { [unowned self] in
        self.documentPicker.openDocumentPicker(presentOn: self) { (result) in
            switch result {
            case .success(let firmware):
                self.firmware = firmware
                (self.sections[1] as? DFUFirmwareSizeSection)?.firmware = firmware
                self.tableView.reloadSections([1], with: .none)
            case .failure(let error): self.displayErrorAlert(error: error)
            }
        }
    }
    
    private lazy var updateSection = DFUUpdateSection() { [unowned self] in
        self.router.goToUpdate(firmware: self.firmware, peripheral: self.bluetoothManager.peripheral)
    }
    
    init(firmware: DFUFirmware, bluetoothManager: PeripheralHolder, router: DFURouterType) {
        self.firmware = firmware
        self.bluetoothManager = bluetoothManager
        self.router = router
        
        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.registerCellClass(cell: NordicRightDetailTableViewCell.self)
        tableView.registerCellNib(cell: DFUFirmwareSizeSchemeCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        
        navigationItem.title = "Ready for update"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sections[indexPath.section].action()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        sections[indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].sectionTitle
    }
}
