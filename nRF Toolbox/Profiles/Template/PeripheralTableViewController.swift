//
//  PeripheralTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

struct Peripheral {
    struct Service {
        struct Characteristic {
            enum Action {
                case read, write, readWrite, notify(Bool)
            }
            
            let uuid: CBUUID
            let action: Action
        }
        let uuid: CBUUID
        let characteristics: [Characteristic]
    }
    let uuid: CBUUID
    let services: [Service]?
}

extension Peripheral.Service {
    static let battery = Peripheral.Service(uuid: CBUUID.Service.battery, characteristics: [
        Peripheral.Service.Characteristic(uuid: CBUUID.Characteristics.Battery.batteryLevel, action: .read)
    ])
}

class PeripheralTableViewController: UITableViewController, StatusDelegate {
    
    private lazy var peripheralManager = PeripheralManager(peripheral: self.peripheralDescription)
    
    private var tbView: UITableView!
    private var batterySection = BatterySection(id: .battery)

    private (set) var activePeripheral: CBPeripheral?
    
    var sections: [Section] { self.internalSections + [batterySection, disconnectSection] }
    var visibleSections: [Section] { sections.filter { !$0.isHidden } }
    var internalSections: [Section] { [] }
    var peripheralDescription: Peripheral { Peripheral(uuid: CBUUID.Profile.bloodGlucoseMonitor, services: [.battery]) }
    var navigationTitle: String { "" }

    private lazy var disconnectSection = ActionSection(id: .disconnect, sectionTitle: "Disconnect", items: [
        ActionSectionItem(title: "Disconnect", style: .destructive) { [unowned self] in
            guard let peripheral = self.activePeripheral else { return }
            self.peripheralManager.closeConnection(peripheral: peripheral)
        }
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        tbView = self.tableView
        peripheralManager.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Battery")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.register(DisclosureTableViewCell.self, forCellReuseIdentifier: "DisclosureTableViewCell")
        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "DetailsTableViewCell")
        
        self.navigationItem.title = navigationTitle
    }
    
    private func disconnect() {
        guard let peripheral = activePeripheral else { return }
        self.peripheralManager.closeConnection(peripheral: peripheral)
    }
    
    // MARK: Table View DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return visibleSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSections[section].numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return visibleSections[indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    // MARK: Table View Delegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return visibleSections[section].sectionTitle
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = visibleSections[indexPath.section]
        selected(item: indexPath.row, in: section)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Table View Handlers
    func selected(item: Int, in section: Section) {
        switch section.id {
        case .disconnect:
            self.disconnect()
        default:
            if let actionSection = section as? ActionSection {
                actionSection.items[item].action()
            } else {
                Log(category: .ui, type: .debug).log(message: "Skipped item #\(item) in section \(section.id)")
            }
        }
    }
    
    func reloadSection(id: Identifier<Section>, animation: UITableView.RowAnimation = .automatic) {
        guard let index = visibleSections.firstIndex(where: { $0.id == id }) else {
            Log(category: .ui, type: .error).log(message: "Cannot upload section \(id)")
            return
        }
        tableView.reloadSections([index], with: .none)
    }
    
    func reloadSections(ids: [Identifier<Section>], animation: UITableView.RowAnimation = .automatic) {
        let indexes = visibleSections.enumerated()
            .filter { ids.contains($0.element.id) }
            .map { $0.offset }
        
        tableView.reloadSections(IndexSet(indexes), with: animation)
    }
    
    func reloadItemInSection(_ sectionId: Identifier<Section>, itemId: Identifier<DetailsTableViewCellModel>, animation: UITableView.RowAnimation = .automatic) {
//        guard let section = visibleSections
//                .enumerated()
//                .first(where: { $0.element.id == sectionId && $0.element is DetailsTableViewSection }),
//            let itemIndex = (section.element as? DetailsTableViewSection)?.items
//                .firstIndex(where: { $0.identifier == itemId })
//            else {
//                Log(category: .ui, type: .error).log(message: "Cannot upload section \(sectionId)")
//            return
//        }
//
//        tableView.reloadRows(at: [IndexPath(row: itemIndex, section: section.offset)], with: animation)
    }
    
    // MARK: Bluetooth events handling
    
    func statusDidChanged(_ status: PeripheralStatus) {
        Log(category: .ble, type: .debug).log(message: "Changed Bluetooth status in \(String(describing: type(of: self))), status: \(status)")
        switch status {
        case .poweredOff:
            activePeripheral = nil
            
            let bSettings: InfoActionView.ButtonSettings = ("Settings", {
                let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
                let app = UIApplication.shared
                app.open(url!, options: [:], completionHandler: nil)

            })
            
            let notContent = InfoActionView.instanceWithParams(message: "Bluetooth is powered off", buttonSettings: bSettings)
            view = notContent
        case .disconnected:
            activePeripheral = nil
            
            for var section in visibleSections {
                section.reset()
            }
            tbView.reloadData()
            
            let bSettings: InfoActionView.ButtonSettings = ("Connect", {
                
                let connectTableViewController = ConnectTableViewController(connectDelegate: self.peripheralManager)
                
                let nc = UINavigationController.nordicBranded(rootViewController: connectTableViewController)
                nc.modalPresentationStyle = .formSheet
                
                self.present(nc, animated: true, completion: nil)
                
                self.peripheralManager.peripheralListDelegate = connectTableViewController
                
                self.peripheralManager.scan(peripheral: self.peripheralDescription)
            })
            
            let notContent = InfoActionView.instanceWithParams(message: "Device is not connected", buttonSettings: bSettings)
            view = notContent
        case .connected(let peripheral):
            dismiss(animated: true, completion: nil)
            activePeripheral = peripheral
            
            activePeripheral?.delegate = self
            activePeripheral?.discoverServices(peripheralDescription.services?.map { $0.uuid } )
            
            view = tbView
        }
    }
    
    func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        let characteristics: [CBUUID]? = self.peripheralDescription
            .services?
            .first(where: { $0.uuid == service.uuid })?
            .characteristics
            .map { $0.uuid }
        
        peripheral.discoverCharacteristics(characteristics, for: service)
    }
    
    func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        peripheralDescription.services?
            .first(where: { $0.uuid == service.uuid })?.characteristics
            .first(where: { $0.uuid == characteristic.uuid })
            .flatMap {
                switch $0.action {
                case .read: peripheral.readValue(for: characteristic)
                case .notify(let enabled): peripheral.setNotifyValue(enabled, for: characteristic)
                default: break
                }
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
        guard let data = characteristic.value, data.count > 0 else { return }
        batterySection.update(with: BatteryCharacteristic(with: data))
        reloadSection(id: .battery)
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
    
    @objc func dismissPresentedViewController() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
