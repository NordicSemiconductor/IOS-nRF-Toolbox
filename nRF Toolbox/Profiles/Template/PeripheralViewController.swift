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
    let mandatoryServices: [CBUUID]?
    let mandatoryCharacteristics: [CBUUID]?
}

class PeripheralViewController: UIViewController, StatusDelegate, AlertPresenter {
    private lazy var peripheralManager = PeripheralManager(peripheral: peripheralDescription)

    var navigationTitle: String { "" }
    var peripheralDescription: PeripheralDescription { SystemLog(category: .app, type: .fault).fault("Override this method in subclass") }
    var requiredServices: [CBUUID]?
    var activePeripheral: CBPeripheral?
    
    private var savedView: UIView!
    private var discoveredServices: [CBUUID] = []
    private var discoveredCharacteristics: [CBUUID] = []
    private var serviceFinderTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        savedView = view
        self.view = InfoActionView.instanceWithParams()

        peripheralManager.delegate = self
        navigationItem.title = navigationTitle
        if #available(iOS 11.0, *) {
            navigationController?.navigationItem.largeTitleDisplayMode = .never
        }
        
        AppUtilities.requestNotificationAuthorization { (_, error) in
            if let e = error {
                self.displayErrorAlert(error: e)
            }
        }
    }

    @objc func disconnect() {
        guard let peripheral = activePeripheral else { return }
        peripheralManager.closeConnection(peripheral: peripheral)
    }
    
    @objc func didEnterBackground(notification: Notification) {
        guard let peripheral = activePeripheral else { return }
        
        let name = peripheral.name ?? "peripheral"
        let msg = "You are still connected to \(name). It will collect data also in background."
            
        AppUtilities.showBackgroundNotification(title: "Still connected", message: msg)
    }

    // MARK: Status changed
    func statusDidChanged(_ status: PeripheralStatus)  {
        SystemLog(category: .ble, type: .debug).log(message: "Changed Bluetooth status in \(String(describing: type(of: self))), status: \(status)")
        switch status {
        case .poweredOff:
            onPowerOffStatus()
        case .disconnected(let error):
            onDisconnectedStatus(error: error)
        case .connecting:
            onConnectingStatus()
        case .connected(let peripheral):
            onConnectedStatus(peripheral: peripheral)
        case .discoveringServicesAndCharacteristics:
            onDiscoveringServicesAndCharacteristics()
        case .discoveredRequiredServicesAndCharacteristics:
            onDiscoveredMandatoryServices()
        case .unauthorized:
            onUnauthorizedStatus()
        }
    }

    func onPowerOffStatus() {
        serviceFinderTimer?.invalidate()
        activePeripheral = nil

        let bSettings: InfoActionView.ButtonSettings = ("Settings", {
            let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
            let app = UIApplication.shared
            app.open(url!, options: [:], completionHandler: nil)
        })

        let notContent = InfoActionView.instanceWithParams(message: "Bluetooth is powered off", buttonSettings: bSettings)
        view = notContent
    }

    func onDisconnectedStatus(error: Error?) {
        serviceFinderTimer?.invalidate()
        activePeripheral = nil

        let bSettings: InfoActionView.ButtonSettings = ("Connect", { [unowned self] in
            self.openConnectorViewController()
        })

        let notContent = InfoActionView.instanceWithParams(message: "No connected device", buttonSettings: bSettings)
        notContent.actionButton.style = .mainAction

        view = notContent
        
        switch error {
        case let e as ConnectionTimeoutError :
            displaySettingsAlert(title: e.title , message: e.readableMessage)
        case let e?:
            displayErrorAlert(error: e)
        default:
            break
        }
        
        if case .background = UIApplication.shared.applicationState {
            let name = activePeripheral?.name ?? "Peripheral"
            let msg = "\(name) is disconnected."
            AppUtilities.showBackgroundNotification(title: "Disconnected", message: msg)
        }
    }

    func onConnectingStatus() {
        let notContent = InfoActionView.instanceWithParams(message: "Connecting...")
        notContent.actionButton.style = .mainAction

        view = notContent
        dismiss(animated: true, completion: nil)
    }

    func onConnectedStatus(peripheral: CBPeripheral) {
        activePeripheral = peripheral

        activePeripheral?.delegate = self
        activePeripheral?.discoverServices(peripheralDescription.services.map { $0.uuid } )

        if let requiredServices = peripheralDescription.mandatoryServices, !requiredServices.isEmpty {
            statusDidChanged(.discoveringServicesAndCharacteristics)
            serviceFinderTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] (t) in
                self?.displayBindingErrorAlert()
                self?.disconnect()
                t.invalidate()
            }
        } else {
            statusDidChanged(.discoveredRequiredServicesAndCharacteristics)
        }
    }

    func onDiscoveringServicesAndCharacteristics() {
        let notContent = InfoActionView.instanceWithParams(message: "Discovering services")
        notContent.messageLabel.text = "Looking for mandatory services and characteristics"
        notContent.titleLabel.numberOfLines = 0
        notContent.titleLabel.textAlignment = .center
        notContent.actionButton.style = .mainAction

        view = notContent
    }

    func onDiscoveredMandatoryServices() {
        serviceFinderTimer?.invalidate()
        view = savedView
    }

    func onUnauthorizedStatus() {
        let bSettings: InfoActionView.ButtonSettings = ("Settings", {
            let url = URL(string: "App-Prefs:root=Bluetooth") //for bluetooth setting
            let app = UIApplication.shared
            app.open(url!, options: [:], completionHandler: nil)
        })

        let notContent = InfoActionView.instanceWithParams(message: "Using Bluetooth is not Allowed", buttonSettings: bSettings)
        notContent.messageLabel.text = "It seems you denied nRF-Toolbox to use Bluetooth. Open settings and allow to use Bluetooth."
        view = notContent
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

        let requiredServices = peripheralDescription.mandatoryServices ?? []
        let requiredCharacteristics = peripheralDescription.mandatoryCharacteristics ?? []

        if Set(requiredServices).subtracting(Set(discoveredServices)).isEmpty &&
               Set(requiredCharacteristics).subtracting(Set(discoveredCharacteristics)).isEmpty &&
                peripheralManager.status != .discoveredRequiredServicesAndCharacteristics  {
            peripheralManager.status = .discoveredRequiredServicesAndCharacteristics
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

        discoveredCharacteristics.append(characteristic.uuid)

        let requiredServices = peripheralDescription.mandatoryServices ?? []
        let requiredCharacteristics = peripheralDescription.mandatoryCharacteristics ?? []

        if Set(requiredServices).subtracting(Set(discoveredServices)).isEmpty &&
               Set(requiredCharacteristics).subtracting(Set(discoveredCharacteristics)).isEmpty &&
                peripheralManager.status != .discoveredRequiredServicesAndCharacteristics {
            peripheralManager.status = .discoveredRequiredServicesAndCharacteristics
        }
    }

    func didUpdateValue(for characteristic: CBCharacteristic) {
        SystemLog(category: .ble, type: .debug).log(message: "Cannot handle update value for characteristic \(characteristic)")
    }
}

extension PeripheralViewController {
    private func displaySettingsAlert(title: String, message: String) {
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
    
    private func displayBindingErrorAlert() {
        let title = "No services discovered"
        let message = "Required service has not been discovered. Check your device, or try to restart Bluetooth in Settings."

        displaySettingsAlert(title: title, message: message)
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
