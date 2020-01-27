//
//  UARTViewController1.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 30.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import AEXML

class UARTViewController1: UIViewController {

    let btManager = BluetoothManager()
    
    private lazy var shareBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
    
    @IBOutlet private var peripheralView: PeripheralView!
    @IBOutlet private var collectionView: UARTCommandListCollectionView!
    @IBOutlet private var macroBtn: NordicButton!
    
    private var preset: UARTPreset = .default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btManager.delegate = self
        btManager.logger = self
        navigationItem.rightBarButtonItem = shareBtn
        
        navigationItem.title = "UART"
        
        peripheralView.disconnect()
        peripheralView.delegate = self
        
        collectionView.commandListDelegate = self
        
        macroBtn.style = .mainAction
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @objc func openConnectorViewController() {
        let scanner = PeripheralScanner(services: nil)
        let connectionController = ConnectionViewController(scanner: scanner)
        connectionController.delegate = self

        let nc = UINavigationController.nordicBranded(rootViewController: connectionController)
        nc.modalPresentationStyle = .formSheet

        self.present(nc, animated: true, completion: nil)
    }
    
    @objc func share() {
        let xml = preset.document
        print(xml.xml)
    }
    
    @IBAction func playMacro() {
        guard btManager.isConnected() else {
            openConnectorViewController()
            return
        }
        let vc = UARTMacrosList(bluetoothManager: btManager, preset: preset)
        
        present(UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false), animated: true)
    }
    
    @IBAction func loadPreset() {
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["public.xml", "public.json"], in: .import)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true)
    }
}

extension UARTViewController1: ConnectionViewControllerDelegate {
    func connected(to peripheral: Peripheral) {
        btManager.connectPeripheral(peripheral: peripheral.peripheral)
    }
}

extension UARTViewController1: BluetoothManagerDelegate {
    
    func didConnectPeripheral(deviceName aName: String?) {
        guard let presented = presentedViewController,
            let scannerNC = presented as? UINavigationController,
            let scanner = scannerNC.viewControllers.first as? ConnectionViewController else {
            return
        }
        
        scanner.dismiss(animated: true, completion: nil)
        peripheralView.connected(peripheral: aName ?? "No Name")
    }
    
    func didDisconnectPeripheral() {
        peripheralView.disconnect()
    }
    
    func peripheralReady() {
        
    }
    
    func peripheralNotSupported() {
        // MARK: Show Alert
        peripheralView.disconnect()
    }
}

extension UARTViewController1: Logger {
    func log(level aLevel: LOGLevel, message aMessage: String) {
        Log(category: .ble, type: .debug).log(message: aMessage)
    }
}

extension UARTViewController1: UARTNewCommandDelegate {
    func createdNewCommand(_ command: UARTCommandModel) {
        guard let selectedItemIndex = collectionView.indexPathsForSelectedItems?.first?.item else {
            return
        }
        
        preset.updateCommand(command, at: selectedItemIndex)
        collectionView.preset = preset
        dismiss(animated: true, completion: nil)
    }
    
}

extension UARTViewController1: PeripheralViewDelegate {
    func requestConnect() {
        self.openConnectorViewController()
    }
}

extension UARTViewController1: UARTCommandListDelegate {
    func selectedCommand(_ command: UARTCommandModel) {
        guard !(command is EmptyModel) else {
            let vc = UARTNewCommandViewController()
            vc.delegate = self
            let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false)
            self.present(nc, animated: true)
            return
        }
        
        guard btManager.isConnected() else {
            openConnectorViewController()
            return
        }
        
        btManager.send(command: command)
    }
}

extension UARTViewController1: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let preset = try UARTPreset(data: data)
            self.preset = preset
            collectionView.preset = preset
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
