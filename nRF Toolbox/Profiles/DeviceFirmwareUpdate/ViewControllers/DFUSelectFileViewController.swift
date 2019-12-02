//
//  DFUSelectFileViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/11/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary
import CoreBluetooth

extension UIButton {
    func adjustBorders() {
        self.layer.borderWidth = 1
        self.layer.borderColor = self.tintColor.cgColor
        self.layer.cornerRadius = 2
    }
}

class DFUSelectFileViewController: UIViewController {

    @IBOutlet var dropView: DFUFileDropView!
    
    @IBOutlet var uploadButton: UIButton!
    @IBOutlet var updateButton: UIButton!
    
    @IBOutlet var fileSizeLabel: UILabel!
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var packtTypeLabel: UILabel!
    
    private var firmware: DFUFirmware?
    
    var peripheral: CBPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Select File"
        dropView.handler = { [unowned self] url in
            self.openFile(url)
        }
        
        uploadButton.adjustBorders()
        updateButton.adjustBorders()
        updateButton.isEnabled = false
        
        dropView.layer.cornerRadius = 5
    }
     
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func select() {
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["com.pkware.zip-archive"], in: .import)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true)
    }
    
    @IBAction func update() {
        guard let firmware = self.firmware else { return }
        let vc = storyboard?.instantiateViewController(withIdentifier: "DFUUpdateViewController") as? DFUUpdateViewController
        vc?.firmware = firmware
        vc?.activePeripheral = self.peripheral
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    private func openFile(_ url: URL) {
        self.firmware = DFUFirmware(urlToZipFile: url)
        if let firmware = self.firmware {
            updateFileInfo(with: firmware)
        } else {
            resetUI()
        }
    }
    
    private func updateFileInfo(with firmware: DFUFirmware) {
        fileNameLabel.text = firmware.fileName
        
        fileSizeLabel.text = try? firmware.fileUrl
            .flatMap { try Data(contentsOf: $0).count }
            .map { Int64($0) }
            .map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .decimal) }
        
        packtTypeLabel.text = "Distribution packet"
        updateButton.isEnabled = true 
    }
    
    private func resetUI() {
        fileNameLabel.text = "Select file"
        fileSizeLabel.text = ""
        updateButton.isEnabled = false
        packtTypeLabel.text = "Select Distribution packet (ZIP) or drop file here."
    }
}

extension DFUSelectFileViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        openFile(url)
    }
}

