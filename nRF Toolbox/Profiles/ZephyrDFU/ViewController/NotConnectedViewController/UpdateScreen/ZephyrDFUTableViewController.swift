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

extension Log.Level {
    var dfuLogLevel: LogLevel {
        switch self {
        case .debug: return .debug
        case .verbose: return .debug
        case .info: return .info
        case .warn: return .warning
        case .error: return .error
        }
    }
}

class ZephyrDFUTableViewController: UpgradeTableViewController<FirmwareUpgradeManager> {
    private let data: Data
    
    private let logger: LogObserver
    
    init(data: Data, peripheral: Peripheral, router: DFUUpdateRouter, logger: LogObserver) {
        self.data = data
        self.logger = logger
        
        super.init(peripheral: peripheral, router: router)
        
        let transport = McuMgrBleTransport(peripheral.peripheral)
        manager = FirmwareUpgradeManager(transporter: transport!, delegate: self)
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
    func log(_ msg: String, atLevel level: Log.Level) {
        logger.logWith(level.dfuLogLevel, message: msg)
    }
    
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        headerView.style = .update
        headerView.startAnimating()
        headerView.statusLabel.text = "UPDATING"
        
        stopSection.items = [.stop]
        controlSection.items = [.pause]
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
    }
    
    func upgradeDidComplete() {
        headerView.style = .done
        headerView.statusLabel.text = "COMPLETED"
        
        controlSection.items = [.showLog, .done]
        stopSection.items = []
        tableView.reloadData()
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        headerView.style = .error
        headerView.statusLabel.text = error.localizedDescription
        
        controlSection.items = [.retry, .showLog, .done]
        stopSection.items = []
        tableView.reloadData()
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
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
