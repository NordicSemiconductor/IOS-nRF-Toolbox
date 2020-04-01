//
// Created by Nick Kibysh on 11/11/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

struct PeripheralDescription {
    struct Service {
        struct Characteristic {
            enum Property {
                case read, notify(Bool)
            }

            let uuid: CBUUID
            let properties: Property?
        }
        let uuid: CBUUID
        let characteristics: [Characteristic]
    }
    let uuid: CBUUID?
    let services: [Service]
}

class PeripheralViewController: UIViewController, StatusDelegate {
    private lazy var peripheralManager = PeripheralManager(peripheral: self.peripheralDescription)

    var navigationTitle: String { "" }
    var peripheralDescription: PeripheralDescription { PeripheralDescription(uuid: CBUUID.Profile.bloodGlucoseMonitor, services: [.battery]) }
    var activePeripheral: CBPeripheral?
    
    private var savedView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralManager.delegate = self
        self.navigationItem.title = navigationTitle
        savedView = view
    }

    @objc func disconnect() {
        guard let peripheral = activePeripheral else { return }
        self.peripheralManager.closeConnection(peripheral: peripheral)
    }

    func statusDidChanged(_ status: PeripheralStatus) {
        SystemLog(category: .ble, type: .debug).log(message: "Changed Bluetooth status in \(String(describing: type(of: self))), status: \(status)")
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

            let bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
                self.openConnectorViewController()
            })
            
            let notContent = InfoActionView.instanceWithParams(message: "No connected device", buttonSettings: bSettings)
            notContent.actionButton.style = .mainAction
            
            view = notContent
        case .connected(let peripheral):
            dismiss(animated: true, completion: nil)
            activePeripheral = peripheral
            
            activePeripheral?.delegate = self
            activePeripheral?.discoverServices(peripheralDescription.services.map { $0.uuid } )
            view = savedView
        }
    }
    
    @objc func openConnectorViewController() {
        let scanner = PeripheralScanner(services: self.peripheralDescription.uuid.map {[$0]})
        let connectionController = ConnectionViewController(scanner: scanner)
        connectionController.delegate = self

        let nc = UINavigationController.nordicBranded(rootViewController: connectionController)
        nc.modalPresentationStyle = .formSheet

        self.present(nc, animated: true, completion: nil)
    }

    func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        let characteristics: [CBUUID]? = self.peripheralDescription
                .services
                .first(where: { $0.uuid == service.uuid })?
                .characteristics
                .map { $0.uuid }

        peripheral.discoverCharacteristics(characteristics, for: service)
    }

    func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        peripheralDescription.services
                .first(where: { $0.uuid == service.uuid })?.characteristics
                .first(where: { $0.uuid == characteristic.uuid })
                .flatMap {
                    switch $0.properties {
                    case .read: peripheral.readValue(for: characteristic)
                    case .notify(let enabled): peripheral.setNotifyValue(enabled, for: characteristic)
                    default: break
                    }
                }
    }

    func didUpdateValue(for characteristic: CBCharacteristic) {
        SystemLog(category: .ble, type: .debug).log(message: "Cannot handle update value for characteristic \(characteristic)")
    }
}

extension PeripheralViewController: ConnectionViewControllerDelegate {
    func requestConnection(to peripheral: Peripheral) {
        self.peripheralManager.connect(peripheral: peripheral)
    }
}

extension PeripheralViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            SystemLog(category: .ble, type: .error).log(message: "Services discovery failed: \(error.localizedDescription)")
            return
        }

        SystemLog(category: .ble, type: .debug).log(message: """
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
            SystemLog(category: .ble, type: .error).log(message: "Characteristic discovery failed: \(error.localizedDescription)")
            return
        }

        SystemLog(category: .ble, type: .debug).log(message: "Discovered characteristics \(service.characteristics.debugDescription) for service: \(service)")

        service.characteristics?.forEach { [unowned service] ch in
            self.didDiscover(characteristic: ch, for: service, peripheral: peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            SystemLog(category: .ble, type: .error).log(message: "Update value for characteristic \(characteristic) failed with error: \(error.localizedDescription). Peripheral: \(peripheral)")
            return
        }

        SystemLog(category: .ble, type: .debug).log(message: "New value in characteristic: \(characteristic.debugDescription)")

        self.didUpdateValue(for: characteristic)
    }

    @objc func dismissPresentedViewController() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
