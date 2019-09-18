//
//  PeripheralTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewController: UITableViewController {
    
    private lazy var bleManager = BLEManager(scanUUID: self.profileUUID )
    
    private var tbView: UITableView!
    private (set) var activePeripheral: CBPeripheral? {
        didSet {
            activePeripheral?.delegate = self
            activePeripheral?.discoverServices(self.scanServices)
            Log(category: .ble, type: .debug).log(message: "Try to discover services \(self.scanServices.debugDescription)")
        }
    }
    
    var sections: [Section] {
        return [self.batterySection] + self.internalSections + [self.deinitSection]
    }
    
    var internalSections: [Section] { return [] }
    
    var profileUUID: CBUUID? { return nil }
    var scanServices: [CBUUID]? { return [CBUUID.Service.battery] }
    private var batterySection = BatterySection()
    private lazy var deinitSection = SingleActionSection(id: "Disconnect", buttonTitle: "Disconnect", style: .destructive) {
        guard let peripheral = self.activePeripheral else { return }
        self.bleManager.manager.cancelPeripheralConnection(peripheral)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tbView = self.tableView
        bleManager.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Battery")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.register(DisclosureTableViewCell.self, forCellReuseIdentifier: "DisclosureTableViewCell")
        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "BatteryTableViewCell")
    }
    
    private func disconnect() {
        guard let peripheral = activePeripheral else { return }
        bleManager.manager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: Table View DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    // MARK: Table View Delegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].sectionTitle
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = self.sections[indexPath.section]
        selected(item: indexPath.row, in: section)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Table View Handlers
    func selected(item: Int, in section: Section) {
        switch section.id {
        case .disconnect:
            self.disconnect()
        case .singleActionSection:
            (section as? SingleActionSection)?.action()
        default:
            if let actionSection = section as? ActionSection {
                actionSection.items[item].action()
            } else {
                Log(category: .ui, type: .debug).log(message: "Skipped item #\(item) in section \(section.id)")
            }
        }
    }
    
    func reloadSection(id: Identifier<Section>, animation: UITableView.RowAnimation = .automatic) {
        guard let index = sections.firstIndex(where: { $0.id == id }) else {
            Log(category: .ui, type: .error).log(message: "Cannot upload section \(id)")
            return
        }
        tableView.reloadSections([index], with: animation)
    }
    
    // MARK: Bluetooth events handling
    func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        switch service.uuid {
        case CBUUID.Service.battery:
            peripheral.discoverCharacteristics([CBUUID.Characteristics.Battery.batteryLevel], for: service)
        default:
            Log(category: .ble, type: .debug).log(message: "Skipped service: \(service)")
        }
    }
    
    func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.Battery.batteryLevel:
            peripheral.readValue(for: characteristic)
        default:
            Log(category: .ble, type: .error).log(message: "Cannot handle characteristics in service \(service.uuid), peripheral: \(service.peripheral)")
        }
    }
    
    func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.Battery.batteryLevel:
            handleBatteryValue(characteristic)
        default:
            Log(category: .ble, type: .debug).log(message: "Cannot handle update value for characteristic \(characteristic)")
        }
    }
    
    // MARK: Bluetooth Characteristic Handling
    func handleBatteryValue(_ characteristic: CBCharacteristic) {
        let data = characteristic.value;
        var pointer = UnsafeMutablePointer<UInt8>(mutating: (data! as NSData).bytes.bindMemory(to: UInt8.self, capacity: data!.count))
        let batteryLevel = CharacteristicReader.readUInt8Value(ptr: &pointer)
        batterySection.batteryLevel = Int(batteryLevel)
        
        Log(category: .ui, type: .debug).log(message: "Battery level: \(batteryLevel)")
        
        let section = sections.firstIndex(where: { $0.id == .battery })
        
        DispatchQueue.main.async {
            section.map { self.tableView.reloadSections([$0], with: .automatic) }
        }
    }
}

extension PeripheralTableViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            Log(category: .ble, type: .error).log(message: "Services discovery failed: \(error.localizedDescription)")
            return
        }
        
        Log(category: .ble, type: .debug).log(message: """
            Found services:
            \(peripheral.services.debugDescription)
            in peripheral: \(peripheral)
            """)
        
        peripheral.services?.forEach { [unowned peripheral] service in
            // peripheral.discoverCharacteristics(nil, for: $0)
            self.didDiscover(service: service, for: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            Log(category: .ble, type: .error).log(message: "Characteristic discovery failed: \(error.localizedDescription)")
            return
        }
        
        Log(category: .ble, type: .debug).log(message: "Discovered characteristics \(service.characteristics.debugDescription) for service: \(service)")
        
        service.characteristics?.forEach { [unowned service] ch in
            self.didDiscover(characteristic: ch, for: service, peripheral: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            Log(category: .ble, type: .error).log(message: "Update value for characteristic \(characteristic) failed with error: \(error.localizedDescription). Peripheral: \(peripheral)")
            return
        }
        
        Log(category: .ble, type: .debug).log(message: "New value in characteristic: \(characteristic.debugDescription)")
        
        self.didUpdateValue(for: characteristic)
    }
}

extension PeripheralTableViewController: StatusDelegate {
    func statusDidChanged(_ status: BLEStatus) {
        Log(category: .ble, type: .debug).log(message: "Changed Bluetooth status in \(String(describing: type(of: self))), status: \(status)")
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
                
                self.bleManager.manager.scanForPeripherals(withServices: self.profileUUID.map { [$0] }, options: nil)
            })
            
            let notContent = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
            self.view = notContent
        case .connected(let peripheral):
            self.dismiss(animated: true, completion: nil)
            self.activePeripheral = peripheral
            self.view = tbView
        }
    }
}
