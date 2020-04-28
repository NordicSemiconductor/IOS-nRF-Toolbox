//
//  UARTViewController.swift
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

class UARTViewController: UIViewController, AlertPresenter {

    let btManager: BluetoothManager!
    
    @IBOutlet private var collectionView: UARTPresetCollectionView!
    @IBOutlet private var disconnectBtn: NordicButton!
    @IBOutlet private var deviceNameLabel: UILabel!
    @IBOutlet private var saveLoadButton: UIButton!
    @IBOutlet private var presetName: UILabel!
    
    private var preset: UARTPreset = .empty
    private weak var router: UARTRouter?
    
    var deviceName: String = "" {
        didSet {
            deviceNameLabel.text = "Connected to \(deviceName)"
        }
    }
    
    init(bluetoothManager: BluetoothManager, uartRouter: UARTRouter) {
        btManager = bluetoothManager
        router = uartRouter
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "UART"
        tabBarItem = UITabBarItem(title: "Preset", image: TabBarIcon.uartPreset.image, selectedImage: TabBarIcon.uartPreset.filledImage)
        
        collectionView.presetDelegate = self
        
        disconnectBtn.style = .destructive
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func savePreset() {
        let xml = preset.document
        print(xml.xml)
        
        if #available(iOS 11.0, *) {
            openDocumentPicker()
        } else {
            saveLoadButton.isHidden = true
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
    
    private func loadPreset() {
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["public.xml", "public.json"], in: .import)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true)
    }
    
    @IBAction func disconnect() {
        btManager.cancelPeripheralConnection()
    }
    
    @IBAction func saveLoad(_ sender: UIButton) {
        let alert = UIAlertController(title: "Save or Load preset", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = saveLoadButton
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            self.savePreset()
        }
        
        let loadAction = UIAlertAction(title: "Load", style: .default) { (_) in
            self.loadPreset()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(loadAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func recordMacros() {
        router?.displayMacros(with: preset)
    }
}

extension UARTViewController: UARTNewCommandDelegate {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: UARTCommandModel, index: Int) {
        preset.updateCommand(command, at: index)
        collectionView.preset = preset
        viewController.dismsiss()
    }
    
}

extension UARTViewController: UARTPresetCollectionViewDelegate {
    
    func longTapAtCommand(_ command: UARTCommandModel, at index: Int) {
        openPresetEditor(with: command, index: index)
        collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .top)
    }
    
    func selectedCommand(_ command: UARTCommandModel, at index: Int) {
        guard !(command is EmptyModel) else {
            openPresetEditor(with: command, index: index)
            return
        }
        
        btManager.send(command: command)
    }
}

extension UARTViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let preset = try UARTPreset(data: data)
            self.preset = preset
            presetName.text = preset.name
            collectionView.preset = preset
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
}

@available(iOS 11.0, *)
extension UARTViewController: UIDocumentBrowserViewControllerDelegate {
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
