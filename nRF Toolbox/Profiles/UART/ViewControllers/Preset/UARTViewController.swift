/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
    
    private var preset: UARTPreset = .default
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
        
        collectionView.preset = preset
        collectionView.presetDelegate = self
        
        disconnectBtn.style = .destructive
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func savePreset() {
        
        let alert = UIAlertController(title: "Save preset", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = "Preset name"
        }
        
        let ok = UIAlertAction(title: "Save", style: .default) { (_) in
            let name = alert.textFields?.first?.text
            self.preset.name = name!
            do {
                try CoreDataStack.uart.viewContext.save()
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
        
        /*
        let xml = preset.document
        print(xml.xml)
        
        if #available(iOS 11.0, *) {
            openDocumentPicker()
        } else {
            saveLoadButton.isHidden = true
        }
 */
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
        
        let vc = PresetListViewController()
        vc.presetDelegate = self
        self.present(vc, animated: true, completion: nil)
        
        
        /*
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["public.xml", "public.json"], in: .import)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true)
        */
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
        
        let saveAs = UIAlertAction(title: "Save As", style: .default) { (_) in
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(loadAction)
        alert.addAction(cancelAction)
        
        if !preset.objectID.isTemporaryID {
            alert.addAction(saveAs)
        }
        
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
        fatalError()
        /*
        do {
            let data = try Data(contentsOf: url)
            let preset = try UARTPreset(data: data)
            self.preset = preset
            presetName.text = preset.name
            collectionView.preset = preset
        } catch let error {
            displayErrorAlert(error: error)
        }
 */
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
        fatalError()
        /*
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
 */
        
    }
}

extension UARTViewController: PresetListDelegate {
    
    func didSelectPreset(_ preset: UARTPreset) {
        dismsiss()
        self.preset = preset
        collectionView.preset = preset
        collectionView.reloadData()
    }
    
}
