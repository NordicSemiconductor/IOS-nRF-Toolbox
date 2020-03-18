//
//  ZephyrDFUTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import McuManager

extension FirmwareUpgradeManager: UpgradeManager {
    func stop() {
        cancel()
    }
}

class ZephyrDFUTableViewController: UpgradeTableViewController<FirmwareUpgradeManager> {
    private let data: Data
    
    private let logger: LoggObserver
    
    init(data: Data, peripheral: Peripheral, router: DFUUpdateRouter, logger: LoggObserver) {
        self.data = data
        self.logger = logger
        
        super.init(peripheral: peripheral, router: router)
        
        let transport = McuMgrBleTransport(peripheral.peripheral)
        self.manager = FirmwareUpgradeManager(transporter: transport!, delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update() {
        do {
            try self.manager?.start(data: self.data)
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
        headerView.style = .update
        headerView.startAnimating()
        headerView.statusLabel.text = "UPDATING"
        
        stopSection.items = [.stop]
        controlSection.items = [.pause]
        logger.logWith(.application, message: "Started Update")
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        logger.logWith(.debug, message: "Status changed: old status: \(previousState), new state: \(newState)")
    }
    
    func upgradeDidComplete() {
        headerView.style = .done
        headerView.statusLabel.text = "COMPLETED"
        
        controlSection.items = [.showLog, .done]
        stopSection.items = []
        tableView.reloadData()
        
        logger.logWith(.info, message: "Upgrade Completed!")
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        headerView.style = .error
        headerView.statusLabel.text = error.localizedDescription
        
        controlSection.items = [.retry, .showLog, .done]
        stopSection.items = []
        tableView.reloadData()
        
        logger.logWith(.error, message: "Error: \(error.localizedDescription)")
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        headerView.statusLabel.text = "CANCELED"
        
        controlSection.items = [.showLog, .done]
        stopSection.items = []
        tableView.reloadData()
        
        logger.logWith(.info, message: "Upgrade was canceled")
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        let percent = Float(bytesSent) / Float(imageSize)
        headerView.progressView.progress = percent
        
        logger.logWith(.verbose, message: "Bytes sent: \(bytesSent) of \(imageSize)")
    }
    
    
}
