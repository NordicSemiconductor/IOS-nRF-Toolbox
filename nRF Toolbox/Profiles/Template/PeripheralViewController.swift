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
    let requiredServices: [CBUUID]?
}

class PeripheralViewController: UIViewController, StatusDelegate, AlertPresenter {
    private lazy var peripheralManager = PeripheralManager(peripheral: peripheralDescription)

    var navigationTitle: String { "" }
    var peripheralDescription: PeripheralDescription { SystemLog(category: .app, type: .fault).fault("Override this method in subclass") }
    var requiredServices: [CBUUID]?
    var activePeripheral: CBPeripheral?
    
    private var savedView: UIView!
    private var discoveredServices: [CBUUID] = []
    private var serviceFinderTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralManager.delegate = self
        navigationItem.title = navigationTitle
        savedView = view
    }

    @objc func disconnect() {
        guard let peripheral = activePeripheral else { return }
        peripheralManager.closeConnection(peripheral: peripheral)
    }

    func statusDidChanged(_ status: PeripheralStatus) {
        SystemLog(category: .ble, type: .debug).log(message: "Changed Bluetooth status in \(String(describing: type(of: self))), status: \(status)")
        switch status {
        case .poweredOff:
            serviceFinderTimer?.invalidate()
            activePeripheral = nil

            let bSettings: InfoActionView.ButtonSettings = ("Settings", {
                let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
                let app = UIApplication.shared
                app.open(url!, options: [:], completionHandler: nil)
            })

            let notContent = InfoActionView.instanceWithParams(message: "Bluetooth is powered off", buttonSettings: bSettings)
            view = notContent
        case .disconnected:
            serviceFinderTimer?.invalidate()
            activePeripheral = nil

            let bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
                self.openConnectorViewController()
            })
            
            let notContent = InfoActionView.instanceWithParams(message: "No connected device", buttonSettings: bSettings)
            notContent.actionButton.style = .mainAction
            
            view = notContent
            
        case .connecting:
            let notContent = InfoActionView.instanceWithParams(message: "Connecting...")
            notContent.actionButton.style = .mainAction
            
            view = notContent
            dismiss(animated: true, completion: nil)
            
        case .connected(let peripheral):
            activePeripheral = peripheral
            
            activePeripheral?.delegate = self
            activePeripheral?.discoverServices(peripheralDescription.services.map { $0.uuid } )
            
            if let requiredServices = peripheralDescription.requiredServices, !requiredServices.isEmpty {
                statusDidChanged(.discoveringServices)
                serviceFinderTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] (t) in
                    self?.displayBindingErrorAlert()
                    self?.disconnect()
                    t.invalidate()
                }
            } else {
                statusDidChanged(.discoveredRequiredServices)
            }

        case .discoveringServices:
            let notContent = InfoActionView.instanceWithParams(message: "Discovering Services...")
            notContent.actionButton.style = .mainAction
            
            view = notContent
        case .discoveredRequiredServices:
            serviceFinderTimer?.invalidate()
            view = savedView
        }
    }
    
    @objc func openConnectorViewController() {
        let scanner = PeripheralScanner(services: peripheralDescription.uuid.map {[$0]})
        let connectionController = ConnectionViewController(scanner: scanner)
        connectionController.delegate = self

        let nc = UINavigationController.nordicBranded(rootViewController: connectionController)
        nc.modalPresentationStyle = .formSheet

        present(nc, animated: true, completion: nil)
    }

    func didDiscover(service: CBService, for peripheral: CBPeripheral) {
        let characteristics: [CBUUID]? = peripheralDescription
                .services
                .first(where: { $0.uuid == service.uuid })?
                .characteristics
                .map { $0.uuid }

        peripheral.discoverCharacteristics(characteristics, for: service)
        
        discoveredServices.append(service.uuid)
        guard let requiredServices = peripheralDescription.requiredServices else {
            serviceFinderTimer?.invalidate()
            return
        }
        if Set(requiredServices).subtracting(Set(discoveredServices)).isEmpty {
            statusDidChanged(.discoveredRequiredServices)
        }
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

extension PeripheralViewController {
    private func displayBindingErrorAlert() {
        let title = "No services discovered"
        let message = "It seems there're no required services. Check your device or try to turn off / on bluetooth in settings"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
            let app = UIApplication.shared
            app.open(url!, options: [:], completionHandler: nil)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}

extension PeripheralViewController: ConnectionViewControllerDelegate {
    func requestConnection(to peripheral: Peripheral) {
        peripheralManager.connect(peripheral: peripheral)
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
            didDiscover(service: service, for: peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            SystemLog(category: .ble, type: .error).log(message: "Characteristic discovery failed: \(error.localizedDescription)")
            return
        }

        SystemLog(category: .ble, type: .debug).log(message: "Discovered characteristics \(service.characteristics.debugDescription) for service: \(service)")

        service.characteristics?.forEach { [unowned service] ch in
            didDiscover(characteristic: ch, for: service, peripheral: peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            SystemLog(category: .ble, type: .error).log(message: "Update value for characteristic \(characteristic) failed with error: \(error.localizedDescription). Peripheral: \(peripheral)")
            return
        }

        SystemLog(category: .ble, type: .debug).log(message: "New value in characteristic: \(characteristic.debugDescription)")

        didUpdateValue(for: characteristic)
    }

    @objc func dismissPresentedViewController() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
