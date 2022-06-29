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
import iOSMcuManagerLibrary
import NordicDFU

extension FirmwareUpgradeManager: UpgradeManager {
    func stop() {
        cancel()
    }
}

class ZephyrDFUTableViewController: UpgradeTableViewController<FirmwareUpgradeManager> {
    private let firmware: McuMgrFirmware
    
    private let logger: McuMgrLogObserver
    
    init(firmware: McuMgrFirmware, peripheral: Peripheral, router: DFUUpdateRouter, logger: McuMgrLogObserver) {
        self.firmware = firmware
        self.logger = logger
        
        super.init(peripheral: peripheral, router: router)
        
        let transport = McuMgrBleTransport(peripheral.peripheral)
        manager = FirmwareUpgradeManager(transporter: transport, delegate: self)
        manager?.logDelegate = logger
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update() {
        do {
            try manager?.start(images: firmware.tupleRepresentation)
        } catch let error {
            headerView.style = .error
            headerView.statusLabel.text = error.localizedDescription
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if manager?.isInProgress() == true {
            headerView.startAnimating()
        }
    }
}

extension ZephyrDFUTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        [controlSection, stopSection][section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        [controlSection, stopSection][indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        [controlSection, stopSection][indexPath.section].didSelectItem(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ZephyrDFUTableViewController: FirmwareUpgradeDelegate {
    
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        logger.shouldLog = false
        
        headerView.style = .update
        headerView.startAnimating()
        headerView.statusLabel.text = "UPDATING"
        
        stopSection.items = [.stop]
        controlSection.items = [.pause]
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {

    }
    
    func upgradeDidComplete() {
        logger.shouldLog = true
        
        headerView.style = .done
        headerView.statusLabel.text = "COMPLETED"
        
        controlSection.items = [.showLog, .done]
        stopSection.items = []
        tableView.reloadData()
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        logger.shouldLog = true
        
        headerView.style = .error
        headerView.statusLabel.text = error.localizedDescription
        
        controlSection.items = [.retry, .showLog, .done]
        stopSection.items = []
        tableView.reloadData()
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        logger.shouldLog = true
        
        headerView.statusLabel.text = "CANCELED"
        
        controlSection.items = [.showLog, .done]
        stopSection.items = []
        tableView.reloadData()
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        let percent = Float(bytesSent) / Float(imageSize)
        headerView.progressView.progress = percent
    }
}
