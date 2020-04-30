//
//  ZephyrDFUTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import McuManager
import iOSDFULibrary

extension FirmwareUpgradeManager: UpgradeManager {
    func stop() {
        cancel()
    }
}

class ZephyrDFUTableViewController: UpgradeTableViewController<FirmwareUpgradeManager> {
    private let data: Data
    
    private let logger: McuMgrLogObserver
    
    init(data: Data, peripheral: Peripheral, router: DFUUpdateRouter, logger: McuMgrLogObserver) {
        self.data = data
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
            try manager?.start(data: data)
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
