//
//  ConnectTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConnectTableViewController: UITableViewController {
    let connectDelegate: ConnectDelegate
    private var peripherals: [ScannedPeripheral] = []
    
    init(connectDelegate: ConnectDelegate) {
        self.connectDelegate = connectDelegate
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        Log(category: .ui, type: .fault).fault("init(coder:) has not been implemented for ConnectTableViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Devices"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let peripheral = peripherals[indexPath.row]
        cell?.textLabel?.text = peripheral.name
        cell?.imageView?.image = UIImage(rssi: peripheral.rssi)
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.connectDelegate.connect(peripheral: self.peripherals[indexPath.row])
    }
    
}

extension ConnectTableViewController: DeviceListDelegate {
    func peripheralsFound(_ peripherals: [ScannedPeripheral]) {
        self.peripherals = peripherals
        tableView.reloadData()
    }
}
