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

class DFUSelectFileViewController: UIViewController {
    
    enum State {
        case readyToOpen, unsupportedFile, readyToUpdate(DFUFirmware), updating, completed
    }

    @IBOutlet var dropView: DFUFileDropView!
    
    @IBOutlet var uploadButton: UIButton!
    @IBOutlet var updateButton: UIButton!
    
    @IBOutlet var fileSizeLabel: UILabel!
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var fileView: FirmwareProgressImage!
    @IBOutlet var fileInfoContainer: UIView!
    
    private var firmware: DFUFirmware?
    
    var peripheral: CBPeripheral!
    
    var state: State = .readyToOpen {
        didSet {
            switch state {
            case .readyToOpen:
                fileView.parts = [ProgressPart(parts: 1, color: .nordicBlue)]
            case .unsupportedFile:
                fileView.parts = [ProgressPart(parts: 1, color: .nordicRed)]
            case .completed:
                fileView.parts = [ProgressPart(parts: 1, color: .nordicGreen)]
            case .readyToUpdate(let firmware):
                updateFileInfo(with: firmware)
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Select File"
        dropView.handler = { [unowned self] url in
            self.openFile(url)
        }
        
        updateButton.isEnabled = false
        
        dropView.layer.cornerRadius = 5
        fileView.inactiveColor = .gray
        fileView.image = UIImage(named: "ic_document")
        fileView.progress = 1
        
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
    }
    
    private func openFile(_ url: URL) {
        self.firmware = DFUFirmware(urlToZipFile: url)
        guard let firmware = self.firmware else {
            self.state = .unsupportedFile
            return
        }
        
        self.state = .readyToUpdate(firmware)
    }
    
    private func updateFileInfo(with firmware: DFUFirmware) {
        fileInfoContainer.subviews.forEach { $0.removeFromSuperview() }
        fileView.setParts(with: firmware)
        let fileInfo = FileSizeView()
        fileInfo.update(with: firmware)
        fileInfoContainer.addSubview(fileInfo)
        fileInfo.addZeroBorderConstraints()
        
        fileSizeLabel.text = try? firmware.fileUrl
            .flatMap { try Data(contentsOf: $0).count }
            .map { Int64($0) }
            .map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .decimal) }
        fileSizeLabel.isHidden = false
        
        fileNameLabel.text = firmware.fileName
        fileNameLabel.isHidden = false 
    }
    
}

extension DFUSelectFileViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        openFile(url)
    }
}

