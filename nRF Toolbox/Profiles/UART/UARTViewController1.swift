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

extension UIImage {
    convenience init?(name: String, systemName: String) {
        if #available(iOS 13, *) {
            self.init(systemName: systemName)
        } else {
            self.init(named: name)
        }
    }
}

class UARTViewController1: UIViewController, AlertPresenter {

    let btManager: BluetoothManager!
    
    private lazy var shareBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
    
    @IBOutlet private var collectionView: UARTCommandListCollectionView!
    
    private var preset: UARTPreset = .default
    private lazy var loggerController = UARTLoggerViewController(bluetoothManager: self.btManager)
    
    init(bluetoothManager: BluetoothManager) {
        self.btManager = bluetoothManager
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btManager.delegate = self
        btManager.logger = self
        navigationItem.rightBarButtonItem = shareBtn
        
        navigationItem.title = "UART"
        tabBarItem = UITabBarItem(title: "Preset", image: TabBarIcon.uartPreset.image, selectedImage: TabBarIcon.uartPreset.filledImage)
        
        collectionView.commandListDelegate = self
        
        btManager.logger = loggerController.logger
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
        
        if #available(iOS 11.0, *) {
            openDocumentPicker()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 11.0, *)
    func openDocumentPicker() {
        let vc = UIDocumentBrowserViewController()
        vc.allowsDocumentCreation = true
        vc.allowsPickingMultipleItems = false
        present(vc, animated: true, completion: nil)
        vc.delegate = self
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
    }
    
    func didDisconnectPeripheral() {
        
    }
    
    func peripheralReady() {
        
    }
    
    func peripheralNotSupported() {
        displayErrorAlert(error: QuickError(message: "Peripheral not supported"))
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
    
    func requestDisconnect() {
        btManager.cancelPeripheralConnection()
    }
}

extension UARTViewController1: UARTCommandListDelegate {
    
    func longTapAtCommand(_ command: UARTCommandModel, at index: Int) {
        let vc = UARTNewCommandViewController(command: command)
        vc.delegate = self
        let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false)
        self.present(nc, animated: true)
        collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .top)
    }
    
    func selectedCommand(_ command: UARTCommandModel, at index: Int) {
        guard !(command is EmptyModel) else {
            let vc = UARTNewCommandViewController(command: command)
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

@available(iOS 11.0, *)
extension UARTViewController1: UIDocumentBrowserViewControllerDelegate {
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        let alert = UIAlertController(title: "Enter the preset's name", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = "name"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let name = alert.textFields?.first?.text else {
                return
            }
            
            self.save(name: name, controller: controller, importHandler: importHandler)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        controller.present(alert, animated: true, completion: nil)
    }
    
    private func save(name: String, controller: UIDocumentBrowserViewController, importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let doc = XMLDocument(name: name)
        preset.name = name
        doc.doc = preset.document
        
        let url = doc.fileURL
        
        doc.save(to: url, for: .forCreating) { (saveSuccess) in
            guard saveSuccess else {
                importHandler(nil, .move)
                return
            }
            
            doc.close { (closeSuccessful) in
                guard closeSuccessful else {
                    importHandler(nil, .move)
                    return
                }
                importHandler(url, .move)
                controller.dismsiss()
            }
        }
        
    }
}
