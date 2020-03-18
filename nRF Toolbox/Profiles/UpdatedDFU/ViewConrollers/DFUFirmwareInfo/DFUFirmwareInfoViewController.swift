//
//  DFUFirmwareInfoViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class DFUFirmwareInfoViewController: UITableViewController, AlertPresenter {

    let router: DFURouterType
    private var firmware: DFUFirmware
    let bluetoothManager: PeripheralHolder
    private let documentPicker = DFUDocumentPicker()
    private lazy var sections: [DFUActionSection] = [self.deviceInfoSection, self.firmwareInfoSection, self.updateSection]
    
    private lazy var deviceInfoSection = DFUDeviceInfoSection(peripheral: bluetoothManager.peripheral) { [unowned self] in
        self.router.goToBluetoothConnector(scanner: PeripheralScanner(services: []), presentationType: .present) { (p) in
            self.presentedViewController?.dismsiss()
            (self.sections[0] as? DFUDeviceInfoSection)?.peripheral = p
            self.tableView.reloadSections([0], with: .none)
        }
    }
    
    private lazy var firmwareInfoSection = DFUFirmwareSizeSection(firmware: firmware) { [unowned self] in
        self.documentPicker.openDocumentPicker(presentOn: self) { (result) in
            switch result {
            case .success(let firmware):
                self.firmware = firmware
                (self.sections[1] as? DFUFirmwareSizeSection)?.firmware = firmware
                self.tableView.reloadSections([1], with: .none)
            case .failure(let error): self.displayErrorAlert(error: error)
            }
        }
    }
    
    private lazy var updateSection = DFUUpdateSection() { [unowned self] in
        self.router.goToUpdate(firmware: self.firmware, peripheral: self.bluetoothManager.peripheral)
    }
    
    init(firmware: DFUFirmware, bluetoothManager: PeripheralHolder, router: DFURouterType) {
        self.firmware = firmware
        self.bluetoothManager = bluetoothManager
        self.router = router
        
        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.registerCellClass(cell: NordicRightDetailTableViewCell.self)
        tableView.registerCellNib(cell: DFUFirmwareSizeSchemeCell.self)
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        
        navigationItem.title = "Ready for update"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sections[indexPath.section].action()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].dequeCell(for: indexPath.row, from: tableView)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].sectionTitle
    }
}
