//
//  GMTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

extension CBUUID {
    struct Service {
        static let battery = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")
        // TODO: Change to correct
        static let bloodPreasureMonitor = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")
    }
    
    struct Characteristics {
        static let batteryLevel = CBUUID(string: "00002A19-0000-1000-8000-00805F9B34FB")
    }
}

protocol Section {
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell
    var numberOfItems: Int { get }
    var sectionTitle: String { get }
}

struct BatterySection: Section {
    let numberOfItems = 1
    let sectionTitle = "Battery"
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Battery")
        cell?.textLabel?.text = "Battery: \(self.batteryLevel)"
        return cell!
    }
    
    var batteryLevel: Int = 0
}

extension Array where Element == Section {
    subscript(index: GMTableViewController.SectionIndex) -> Element {
        get { return self[index.rawValue] }
        set { self[index.rawValue] = newValue }
    }
}

extension UITableView {
    func reloadSection(_ index: GMTableViewController.SectionIndex, with rowAnimation: UITableView.RowAnimation = .automatic) {
        self.reloadSections([index.rawValue], with: rowAnimation)
    }
}

extension CBPeripheral {
    var debugName: String {
        return name ?? "__unnamed__"
    }
    
    var debugSevicesDescription: String {
        guard let services = self.services else { return "__no_services__" }
        
        return services.map { "UUID = \($0.uuid), is primary = \($0.isPrimary)" }
            .joined(separator: "\n")
    }
}

extension CBService {
    var debugCharacteristicsDescription: String {
        guard let characteristics = self.characteristics else { return "__no_characteristics__"}
        
        return characteristics.map { "UUID = \($0.uuid)" }
            .joined(separator: "\n")
    }
}

class GMTableViewController: UITableViewController {
    
    struct SectionIndex: RawRepresentable {
        var rawValue: Int
        init?(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let battery = SectionIndex(rawValue: 0)!
    }
    
    let bleManager: BLEManager
    private var tbView: UITableView!
    private var activePeripheral: CBPeripheral? {
        didSet {
            activePeripheral?.delegate = self
            activePeripheral?.discoverServices(nil)
        }
    }
    let service: BLEService
    
    var sections: [Section] = [BatterySection()]
    
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
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Battery")
    }
    
    // MARK: Table View DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfItems
    }
    
    // MARK: Table View Delegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].sectionTitle
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    // MARK: Bluetooth events handling
    func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        switch service.uuid {
        case CBUUID.Service.battery:
            peripheral.discoverCharacteristics([CBUUID.Characteristics.batteryLevel], for: service)
        default:
            Log(category: .ble, type: .debug).log(message: "Skipped service: \(service)")
        }
    }
    
    func didDiscoverCharacteristics(for service: CBService) {
        switch service.uuid {
        case CBUUID.Service.battery:
            service.characteristics?
                .first(where: { $0.uuid == CBUUID.Characteristics.batteryLevel })
                .map { self.activePeripheral?.readValue(for: $0) }
        default:
            Log(category: .ble, type: .error).log(message: "Cannot handle characteristics in service \(service.uuid), peripheral: \(service.peripheral)")
        }
    }
    
    func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.batteryLevel:
            handleBatteryValue(characteristic)
        default:
            break
        }
    }
    
    // MARK: Bluetooth Characteristic Handling
    func handleBatteryValue(_ characteristic: CBCharacteristic) {
        guard var batterySection = sections[.battery] as? BatterySection else {
            Log(category: .ui, type: .error).log(message: "Cannot find battery section")
            return
        }
        
        let data = characteristic.value;
        var pointer = UnsafeMutablePointer<UInt8>(mutating: (data! as NSData).bytes.bindMemory(to: UInt8.self, capacity: data!.count))
        let batteryLevel = CharacteristicReader.readUInt8Value(ptr: &pointer)
        batterySection.batteryLevel = Int(batteryLevel)
        sections[.battery] = batterySection
        
        Log(category: .ui, type: .debug).log(message: "Battery level: \(batteryLevel)")
        
        DispatchQueue.main.async {
            self.tableView.reloadSection(.battery)
        }
    }
}

extension GMTableViewController: StatusDelegate {
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
                self.bleManager.manager.scanForPeripherals(withServices: self.service.uuid.map { [CBUUID(nsuuid: $0)] }, options: nil)
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

extension GMTableViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            Log(category: .ble, type: .error).log(message: "Services discovery failed: \(error.localizedDescription)")
            return
        }
        
        Log(category: .ble, type: .debug).log(message: """
            Found services:
            \(peripheral.debugSevicesDescription)
            in peripheral: \(peripheral.debugName)
            """)
        
        // TODO: set required characteristics
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            Log(category: .ble, type: .error).log(message: "Characteristic discovery failed: \(error.localizedDescription)")
            return
        }
        
        Log(category: .ble, type: .debug).log(message: "Discovered characteristics \(service.debugCharacteristicsDescription) for service: \(service)")
        
        self.didDiscoverCharacteristics(for: service)
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
