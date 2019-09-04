//
//  GMTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class GMTableViewController: UITableViewController {
    
    let bleManager: BLEManager
    private var tbView: UITableView!
    let service: BLEService
    
    init(model: BLEService) {
        self.service = model
        let uuid = model.uuid.map { CBUUID(nsuuid: $0) }
        self.bleManager = BLEManager(scanUUID: uuid)
        
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tbView = self.tableView
        bleManager.delegate = self
        
    }
}

extension GMTableViewController: StatusDelegate {
    func statusDidChanged(_ status: BLEStatus) {
        switch status {
        case .poweredOff:
            let bSettings: InfoActionView.ButtonSettings = ("Settings", {
                let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
                let app = UIApplication.shared
                app.openURL(url!)
            })
            
            let notContent = InfoActionView.instanceWithParams(message: "Bluetooth is powered off", buttonSettings: bSettings)
            self.view = notContent
        case .disconnected:
            let bSettings: InfoActionView.ButtonSettings = ("Connect", {
                
                let connectTableViewController = ConnectTableViewController(connectDelegate: self.bleManager)
                connectTableViewController.navigationItem.title = "Connnect"
                connectTableViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: connectTableViewController, action: #selector(self.dismiss(animated:completion:)))
                
                let nc = UINavigationController.nordicBranded(rootViewController: connectTableViewController)
                nc.modalPresentationStyle = .formSheet
                
                self.present(nc, animated: true, completion: nil)
                
                self.bleManager.deviceListDelegate = connectTableViewController
                self.bleManager.manager.scanForPeripherals(withServices: self.service.uuid.map { [CBUUID(nsuuid: $0)] }, options: nil)
            })
            
            let notContent = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
            self.view = notContent
        default:
            self.dismiss(animated: true, completion: nil)
            self.view = tbView
        }
    }
    
    
}
