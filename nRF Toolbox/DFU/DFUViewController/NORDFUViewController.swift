//
//  NORDFUViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 12/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary

class NORDFUViewController: NORBaseViewController, NORScannerDelegate, NORFileSelectionDelegate, LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    
    //MARK: - Class properties
    var selectedPeripheral : CBPeripheral?
    var centralManager     : CBCentralManager?
    var dfuController      : DFUServiceController?
    var selectedFirmware   : DFUFirmware?
    var selectedFileURL    : URL?
    var isImportingFile = false

    //MARK: - UIViewController Outlets

    @IBOutlet weak var dfuLibraryVersionLabel: UILabel!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileSize: UILabel!
    @IBOutlet weak var fileType: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var selectFileButton: UIButton!
    @IBOutlet weak var uploadStatus: UILabel!
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var uploadPane: UIView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var progress: UIProgressView!
 
    //MARK: - UIViewController Actions
    
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        handleAboutButtonTapped()
    }
    @IBAction func uploadButtonTapped(_ sender: AnyObject) {
        handleUploadButtonTapped()
    }
    
    //MARK: - UIVIewControllerDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalLabel.transform = CGAffineTransform(translationX: -(verticalLabel.frame.width/2) + (verticalLabel.frame.height / 2), y: 0.0).rotated(by: -.pi / 2)
        
        if isImportingFile {
            isImportingFile = false
            self.onFileSelected(withURL: selectedFileURL!)
        }

        self.dfuLibraryVersionLabel.text = "DFU Library version \(NORAppUtilities.iOSDFULibraryVersion)"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //if DFU peripheral is connected and user press Back button then disconnect it
        if self.isMovingFromParentViewController && dfuController != nil {
            let aborted = dfuController?.abort()
            if aborted! == false {
                logWith(.application, message: "Aborting DFU process failed")
            }
        }
    }

    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        selectedPeripheral = aPeripheral
        centralManager = aManager
        deviceName.text = aPeripheral.name
        progressLabel.text = nil
        self.updateUploadButtonState()
    }

    //MARK: - NORFileSelectionDelegate
    func onFileImported(withURL aFileURL: URL){
        selectedFileURL = aFileURL
        self.isImportingFile = true
    }

    func onFileSelected(withURL aFileURL: URL) {
        selectedFileURL = aFileURL
        selectedFirmware = nil
        fileName.text = nil
        fileSize.text = nil
        fileType.text = nil

        let fileNameExtension = aFileURL.pathExtension.lowercased()
        
        if fileNameExtension == "zip" {
            selectedFirmware = DFUFirmware(urlToZipFile: aFileURL)
            var appPresent         = false
            var softDevicePresent  = false
            var bootloaderPresent  = false
            if let appSize = selectedFirmware?.size.application {
                if appSize > 0 {
                    appPresent = true
                }
            }
            if let sdSize = selectedFirmware?.size.softdevice {
                if sdSize > 0 {
                    softDevicePresent = true
                }
            }
            if let blSize = selectedFirmware?.size.bootloader {
                if blSize > 0 {
                    bootloaderPresent = true
                }
            }
            
            if bootloaderPresent && softDevicePresent && appPresent {
                showFirmwarePartSelectionAlert(withChoices: [.softdeviceBootloaderApplication, .softdeviceBootloader, .application])
                return
            } else {
                updateViewForSelectedDistributionPacketWithType(aType: .softdeviceBootloaderApplication, andFileURL: aFileURL)
            }
        } else {
            showFileTypeSelectionAlert()
        }

    }

    func updateViewForSelectedDistributionPacketWithType(aType: DFUFirmwareType, andFileURL aFileURL: URL) {
        selectedFirmware = DFUFirmware(urlToZipFile: aFileURL, type: aType)
        if selectedFirmware != nil && selectedFirmware?.fileName != nil {
            fileName.text = selectedFirmware?.fileName
            let content = try? Data(contentsOf: aFileURL)
            fileSize.text = String(format: "%lu bytes", (content?.count)!)
            fileType.text = "Distribution packet"
        } else {
            selectedFirmware = nil
            selectedFileURL  = nil
            NORDFUConstantsUtility.showAlert(message: "Seleted file is not supported")
        }
        self.updateUploadButtonState()
    }

    func showFileTypeSelectionAlert() {
        let fileTypeAlert = UIAlertController(title: "Firmware type", message: "Please select the type of this firmware", preferredStyle: .actionSheet)
        
        let softdeviceAction = UIAlertAction(title: "Softdevice", style: .default) { (anAction) in
            self.didSelectFirmwareType(.softdevice)
        }
        
        let bootloaderAction = UIAlertAction(title: "Bootloader", style: .default) { (anAction) in
            self.didSelectFirmwareType(.bootloader)
        }
        
        let applicationAction = UIAlertAction(title: "Application", style: .default) { (anAction) in
            self.didSelectFirmwareType(.application)
        }
        
        let softdeviceBootloaderAction = UIAlertAction(title: "Softdevice + Bootloader", style: .default) { (anAction) in
            self.didSelectFirmwareType(.softdeviceBootloader)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (anAction) in
            DispatchQueue.main.async {
                self.selectedFileURL = nil
                self.updateUploadButtonState()
                self.progressLabel.text = nil
            }
        }
        
        fileTypeAlert.addAction(applicationAction)
        fileTypeAlert.addAction(softdeviceAction)
        fileTypeAlert.addAction(bootloaderAction)
        fileTypeAlert.addAction(softdeviceBootloaderAction)
        fileTypeAlert.addAction(cancelAction)
        
        present(fileTypeAlert, animated: true, completion: nil)
    }

    func showFirmwarePartSelectionAlert(withChoices choices: [DFUFirmwareType]) {
        let firmwarePartAlert = UIAlertController(title: "Firmware part", message: "Please select the parts of this firmware to flash", preferredStyle: .actionSheet)
        for aChoice in choices {
            let choiceAction = UIAlertAction(title: firmwarePartToString(aChoice), style: .default, handler: { (alertAction) in
                self.didSelectFirmwarePart(aChoice)
            })
            firmwarePartAlert.addAction(choiceAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (anAction) in
            DispatchQueue.main.async {
                self.selectedFirmware = nil
                self.selectedFileURL = nil
                self.updateUploadButtonState()
                self.progressLabel.text = nil
            }
        }
        firmwarePartAlert.addAction(cancelAction)
        present(firmwarePartAlert, animated: true, completion: nil)
    }

    func didSelectFirmwarePart(_ aPart: DFUFirmwareType) {
        if let selectedFileURL = selectedFileURL {
            updateViewForSelectedDistributionPacketWithType(aType: aPart, andFileURL: selectedFileURL)
        }else{
            print("No file selected")
        }
    }

    func didSelectFirmwareType(_ aFileType: DFUFirmwareType) {
        selectedFirmware = DFUFirmware(urlToBinOrHexFile: selectedFileURL!, urlToDatFile: nil, type: aFileType)
        print(selectedFirmware?.fileUrl ?? "None")
        if selectedFirmware != nil && selectedFirmware?.fileName != nil {
            fileName.text = selectedFirmware?.fileName
            let content = try? Data(contentsOf: selectedFileURL!)
            fileSize.text = String(format: "%d bytes", (content?.count)!)
            DispatchQueue.main.async {
                self.fileType.text = self.firmwareTypeToString(aFileType)
            }
        } else {
            selectedFileURL = nil
            NORDFUConstantsUtility.showAlert(message: "Selected file is not supported")
        }
        DispatchQueue.main.async {
            self.progressLabel.text = nil
            self.updateUploadButtonState()
        }
    }

    func firmwareTypeToString(_ aType: DFUFirmwareType) -> String {
        switch  aType {
            case .application:
                return "Application"
            
            case .bootloader:
                return "Bootloader"
            
            case .softdevice:
                return "SoftDevice"
            
            case .softdeviceBootloader:
                return "SD + BL"
            
            case .softdeviceBootloaderApplication:
                return "APP + SD + BL"
        }
    }
    
    func firmwarePartToString(_ aType: DFUFirmwareType) -> String {
        switch  aType {
        case .application:
            return "Application only"
            
        case .bootloader:
            return "Bootloader only"
            
        case .softdevice:
            return "SoftDevice only"
            
        case .softdeviceBootloader:
            return "System components only"
            
        case .softdeviceBootloaderApplication:
            return "All"
        }
    }

    //MARK: - LoggerDelegate
    func logWith(_ level:LogLevel, message:String){
        var levelString : String?
        switch(level) {
            case .application:
                levelString = "Application"
            case .debug:
                levelString = "Debug"
            case .error:
                levelString = "Error"
            case .info:
                levelString = "Info"
            case .verbose:
                levelString = "Verbose"
            case .warning:
                levelString = "Warning"
        }
        print("\(levelString!): \(message)")
    }

    //MARK: - DFUServiceDelegate
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .connecting:
            uploadStatus.text = "Connecting..."
        case .starting:
            uploadStatus.text = "Starting DFU..."
        case .enablingDfuMode:
            uploadStatus.text = "Enabling DFU Bootloader..."
        case .uploading:
            uploadStatus.text = "Uploading..."
        case .validating:
            uploadStatus.text = "Validating..."
        case .disconnecting:
            uploadStatus.text = "Disconnecting..."
        case .completed:
            NORDFUConstantsUtility.showAlert(message: "Upload complete")
            if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
                NORDFUConstantsUtility.showBackgroundNotification(message: "Upload complete")
            }
            self.clearUI()
        case .aborted:
            NORDFUConstantsUtility.showAlert(message: "Upload aborted")
            if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded(){
                NORDFUConstantsUtility.showBackgroundNotification(message: "Upload aborted")
            }
            self.clearUI()
        }
    }

    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
            NORDFUConstantsUtility.showBackgroundNotification(message: message)
        }
        clearUI()
        DispatchQueue.main.async {
            self.progressLabel.text = "Error: \(message)"
            self.progressLabel.isHidden = false
        }
    }

    //MARK: - DFUProgressDelegate
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        self.progress.setProgress(Float(progress) / 100.0, animated: true)
        progressLabel.text = String("\(progress)% (\(part)/\(totalParts))")
    }
    
    //MARK: - Segue Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if (segue.identifier == "scan") {
                // Set this contoller as scanner delegate
                let aNavigationController = segue.destination as? UINavigationController
                let scannerViewController = aNavigationController?.childViewControllers.first as? NORScannerViewController
                scannerViewController?.delegate = self
            } else if segue.identifier == "FileSegue" {
                let aNavigationController = segue.destination as? UINavigationController
                let barViewController = aNavigationController?.childViewControllers.first as? UITabBarController
                let appFilecsVC = barViewController?.viewControllers?.first as? NORAppFilesViewController
                appFilecsVC?.fileDelegate = self
                let userFilesVC = barViewController?.viewControllers?.last as? NORUserFilesViewController
                userFilesVC?.fileDelegate = self
                
                if selectedFileURL != nil {
                    appFilecsVC?.selectedPath = selectedFileURL
                    userFilesVC?.selectedPath = selectedFileURL
                }
            }
    }
    
    //MARK: - NORDFUViewController implementation
    func handleAboutButtonTapped() {
        self.showAbout(message: NORDFUConstantsUtility.getDFUHelpText())
    }
    
    func handleUploadButtonTapped() {
        guard dfuController != nil else {
            self.performDFU()
            return
        }
        
        // Pause the upload process. Pausing is possible only during upload, so if the device was still connecting or sending some metadata it will continue to do so,
        // but it will pause just before seding the data.
        dfuController?.pause()
        
        let alert = UIAlertController(title: "Abort?", message: "Do you want to abort?", preferredStyle: .alert)
        let abort = UIAlertAction(title: "Abort", style: .destructive, handler: { (anAction) in
            _ = self.dfuController?.abort()
            alert.dismiss(animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (anAction) in
            self.dfuController?.resume()
            alert.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(abort)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }

    func registerObservers() {
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert], categories: nil))
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        }
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    @objc func applicationDidEnterBackgroundCallback() {
        if dfuController != nil {
            NORDFUConstantsUtility.showBackgroundNotification(message: "Uploading firmware...")
        }
    }

    @objc func applicationDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }

    func updateUploadButtonState() {
        uploadButton.isEnabled = selectedFirmware != nil && selectedPeripheral != nil
    }

    func disableOtherButtons() {
        selectFileButton.isEnabled = false
        connectButton.isEnabled = false
    }

    func enableOtherButtons() {
        selectFileButton.isEnabled = true
        connectButton.isEnabled = true
    }

    func clearUI() {
        DispatchQueue.main.async {
            self.dfuController          = nil
            self.selectedPeripheral     = nil
            
            self.deviceName.text        = "DEFAULT DFU"
            self.uploadStatus.text      = nil
            self.uploadStatus.isHidden  = true
            self.progress.progress      = 0.0
            self.progress.isHidden      = true
            self.progressLabel.text     = nil
            self.progressLabel.isHidden = true
            
            self.uploadButton.setTitle("Upload", for: .normal)
            self.updateUploadButtonState()
            self.enableOtherButtons()
            self.removeObservers()
        }
    }

    func performDFU() {
        self.disableOtherButtons()
        progress.isHidden = false
        progressLabel.text = nil
        progressLabel.isHidden = false
        uploadStatus.isHidden = false
        uploadButton.isEnabled = false

        self.registerObservers()
        
        // To start the DFU operation the DFUServiceInitiator must be used
        let initiator = DFUServiceInitiator(centralManager: centralManager!, target: selectedPeripheral!)
        initiator.forceDfu = UserDefaults.standard.bool(forKey: "dfu_force_dfu")
        initiator.packetReceiptNotificationParameter = UInt16(UserDefaults.standard.integer(forKey: "dfu_number_of_packets"))
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        dfuController = initiator.with(firmware: selectedFirmware!).start()
        uploadButton.setTitle("Cancel", for: UIControlState())
        uploadButton.isEnabled = true
    }

}
