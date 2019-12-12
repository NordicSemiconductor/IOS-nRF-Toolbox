//
// Created by Nick Kibysh on 11/11/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary

class DFUViewController: PeripheralViewController {
    
    @IBOutlet private var fileView: DFUFileView!
    @IBOutlet private var textView: LogerTextView!
    
    private lazy var disconnectBtn = UIBarButtonItem(title: "Disconnect", style: .done, target: self, action: #selector(disconnect))
    
    var firmware: DFUFirmware?
    
    private var dfuController: DFUServiceController?
    private var selectedFirmware: DFUFirmware?
    
    init() {
        super.init(nibName: "DFUViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = disconnectBtn
        disconnectBtn.isEnabled = false
        
        navigationItem.title = "DFU"
        fileView.delegate = self
        fileView.fileDelegate = self
        fileView.state = .readyToOpen
    }

    override var peripheralDescription: PeripheralDescription {
        PeripheralDescription(uuid: nil, services: [.battery])
    }

    override func statusDidChanged(_ status: PeripheralStatus) {
        super.statusDidChanged(status)
        
        if case .connected = status {
            disconnectBtn.isEnabled = true
        } else {
            disconnectBtn.isEnabled = false
        }
    }
    
    private func createFirmware(_ url: URL) {
        textView.attributedText = NSAttributedString()
        self.firmware = DFUFirmware(urlToZipFile: url)
        guard let firmware = self.firmware else {
            self.fileView.state = .unsupportedFile
            return
        }
        
        self.fileView.state = .readyToUpdate(firmware)
    }
}

extension DFUViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print(url)
        createFirmware(url)
    }
}

extension DFUViewController: DFUFileViewActionDelegate {
    func openFile(_ fileView: DFUFileView) {
        let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["com.pkware.zip-archive"], in: .import)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true)
    }
    
    func update(_ fileView: DFUFileView) {
        guard let firmware = self.firmware else { return }
        
        var types: [DFUFirmwareType] = []
        
        let applicationPresent = firmware.size.application > 1
        let bootloaderSoftdevicePresent = (firmware.size.bootloader + firmware.size.softdevice) > 1
        
        if applicationPresent {
            types.append(.application)
        }
        
        if bootloaderSoftdevicePresent {
            types.append(.softdeviceBootloader)
        }
        
        if applicationPresent && bootloaderSoftdevicePresent {
            types.append(.softdeviceBootloaderApplication)
        }
        
        guard types.count > 1 else {
            update(with: types[0], firmware: firmware)
            return
        }
        
        let actions = types.map { type in
            UIAlertAction(title: type.desccription, style: .default) { (_) in
                self.update(with: type, firmware: firmware)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = fileView
        
        actions.forEach(alertController.addAction(_:))
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func update(with type: DFUFirmwareType, firmware: DFUFirmware) {
        
        // TODO: @philips77 can we select firmware part just before update?
        
        let initiator = DFUServiceInitiator()
        
        initiator.logger = self.textView
        initiator.delegate = self
        initiator.progressDelegate = self.fileView
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        self.dfuController = initiator.with(firmware: firmware).start(target: self.activePeripheral!)
    }
    
    func pause(_ fileView: DFUFileView) {
        dfuController?.pause()
        fileView.state = .paused
    }
    
    func resume(_ fileView: DFUFileView) {
        dfuController?.resume()
        fileView.state = .updating(.softdeviceBootloaderApplication)
    }
    
    func stop(_ fileView: DFUFileView) {
        
        dfuController?.pause()
        
        let stopAction = UIAlertAction(title: "Stop", style: .destructive) { (_) in
            _ = self.dfuController?.abort()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.dfuController?.resume()
            fileView.state = .updating(.softdeviceBootloaderApplication)
        }
        
        let alert = UIAlertController(title: "Stop", message: "Are you sure you want to stop DFU process", preferredStyle: .alert)
        alert.addAction(cancel)
        alert.addAction(stopAction)
        
        present(alert, animated: true)
    }
    
    func share(_ fileView: DFUFileView) {
        guard let attributedText = self.textView.attributedText else { return }
        let activity = UIActivityViewController(activityItems: [attributedText], applicationActivities: [])
        activity.popoverPresentationController?.sourceView = fileView
        self.present(activity, animated: true, completion: nil)
    }
    
    func done(_ fileView: DFUFileView) {
        fileView.state = .readyToOpen
        textView.attributedText = NSAttributedString()
    }
    
}

extension DFUViewController: DFUFileHandlerDelegate {
    func fileView(_ fileView: DFUFileView, loadedFirmware firmware: DFUFirmware) {
        self.firmware = firmware
        DispatchQueue.main.async {
            self.textView.attributedText = NSAttributedString()
            fileView.state = .readyToUpdate(firmware)
        }
    }
    
    func fileView(_ fileView: DFUFileView, didntOpenFileWithError error: Error) {
        fileView.state = .error(error)
        self.textView.logWith(.error, message: error.localizedDescription)
    }
}

extension DFUViewController: DFUServiceDelegate {
    struct DFUError: Error {
        let error: iOSDFULibrary.DFUError
        let localizedDescription: String
    }

    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .aborted:
            fileView.state = .readyToOpen
        case .completed:
            fileView.state = .completed
        case .uploading:
            fileView.state = .updating(.softdeviceBootloaderApplication)
        default:
            break
        }
    }
    
    func dfuError(_ error: iOSDFULibrary.DFUError, didOccurWithMessage message: String) {
        let error = DFUError(error: error, localizedDescription: message)
        self.fileView.state = .error(error)
        print(message)
    }
}
