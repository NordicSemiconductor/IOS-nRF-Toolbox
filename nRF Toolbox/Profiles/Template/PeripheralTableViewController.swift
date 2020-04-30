//
//  PeripheralTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

extension PeripheralDescription.Service {
    static let battery = PeripheralDescription.Service(uuid: CBUUID.Service.battery, characteristics: [
        PeripheralDescription.Service.Characteristic(uuid: CBUUID.Characteristics.Battery.batteryLevel, properties: .read)
    ])
}

class PeripheralTableViewController: PeripheralViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView: UITableView!
    private var batterySection = BatterySection(id: .battery)

    var sections: [Section] { internalSections + [batterySection, disconnectSection] }
    var visibleSections: [Section] { sections.filter { !$0.isHidden } }
    var internalSections: [Section] { [] }
    
    private var discoveredServices: [CBUUID]?

    private lazy var disconnectSection = ActionSection(id: .disconnect, sectionTitle: "Connection", items: [
        ActionSectionItem(title: "Disconnect", style: .destructive) { [unowned self] in
            guard let peripheral = self.activePeripheral else { return }
            self.disconnect()
        }
    ])

    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }
        self.view = tableView
        
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Battery")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.register(DisclosureTableViewCell.self, forCellReuseIdentifier: "DisclosureTableViewCell")
        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "DetailsTableViewCell")
        
        sections.forEach { $0.registerCells(self.tableView) }
    }

    // MARK: Table View DataSource
    func numberOfSections(in tableView: UITableView) -> Int { visibleSections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visibleSections[section].numberOfItems }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { visibleSections[indexPath.section].dequeCell(for: indexPath.row, from: tableView) }
    
    // MARK: Table View Delegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { visibleSections[section].sectionTitle }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = visibleSections[indexPath.section]
        selected(item: indexPath.row, in: section)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { visibleSections[indexPath.section].cellHeight(for: indexPath.row)
    }

    // MARK: Table View Handlers
    func selected(item: Int, in section: Section) {
        switch section.id {
        case .disconnect:
            disconnect()
        default:
            if let actionSection = section as? ActionSection {
                actionSection.items[item].action()
            } else {
                SystemLog(category: .ui, type: .debug).log(message: "Skipped item #\(item) in section \(section.id)")
            }
        }
    }
    
    func reloadSection(id: Identifier<Section>, animation: UITableView.RowAnimation = .automatic) {
        tableView.reloadData()
    }
    
    func reloadSections(ids: [Identifier<Section>], animation: UITableView.RowAnimation = .automatic) {
        let indexes = visibleSections.enumerated()
            .filter { ids.contains($0.element.id) }
            .map { $0.offset }
        
        tableView.reloadSections(IndexSet(indexes), with: animation)
    }
    
    func reloadItemInSection(_ sectionId: Identifier<Section>, itemId: Identifier<DetailsTableViewCellModel>, animation: UITableView.RowAnimation = .automatic) {
    }
    
    // MARK: Bluetooth events handling

    override func statusDidChanged(_ status: PeripheralStatus) {
        super.statusDidChanged(status)

        switch status {
        case .disconnected:
            for var section in visibleSections {
                section.reset()
            }
        default:
            break
        }

    }

    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Characteristics.Battery.batteryLevel:
            handleBatteryValue(characteristic)
        default:
            SystemLog(category: .ble, type: .debug).log(message: "Cannot handle update value for characteristic \(characteristic)")
        }
    }
    
    // MARK: Bluetooth Characteristic Handling
    func handleBatteryValue(_ characteristic: CBCharacteristic) {
        guard let data = characteristic.value, data.count > 0 else { return }
        batterySection.update(with: BatteryCharacteristic(with: data))
        reloadSection(id: .battery)
    }

    override func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        super.didDiscover(service: service, for: peripheral)
    }

}

