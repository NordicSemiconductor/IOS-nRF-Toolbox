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



class NORDFUViewController: NORBaseViewController, NORScannerDelegate, NORFileTypeSelectionDelegate, NORFileSelectionDelegate, LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    
    //MARK: - Class properties
    var selectedPeripheral : CBPeripheral?
    var centralManager     : CBCentralManager?
    var dfuController      : DFUServiceController?
    var selectedFirmware   : DFUFirmware?
    var selectedFileURL    : URL?
    var isImportingFile = false

    //MARK: - UIViewController Outlets

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
        self.verticalLabel.transform = CGAffineTransform(translationX: -145.0, y: 0.0).rotated(by: CGFloat(-M_PI_2))
        
        if isImportingFile {
            isImportingFile = false
            self.onFileSelected(withURL: selectedFileURL!)
        }
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
        self.updateUploadButtonState()
    }

    //MARK: - NORFileTypeSelectionDelegate
    func onFileTypeSelected(fileType aType: DFUFirmwareType) {
        selectedFirmware = DFUFirmware(urlToBinOrHexFile: selectedFileURL!, urlToDatFile: nil, type: aType)
    
        if selectedFirmware != nil && selectedFirmware?.fileName != nil {
            fileName.text = selectedFirmware?.fileName
            let content = try? Data(contentsOf: selectedFileURL!)
            fileSize.text = String(format: "%d bytes", (content?.count)!)
            
            switch  aType {
            case .application:
                fileType.text = "Application"
                break
            case .bootloader:
                fileType.text = "Bootloader"
                break
            case .softdevice:
                fileType.text = "SoftDevice"
                break
            default:
                fileType.text = "Not implemented yet"
            }
        }else{
            selectedFileURL = nil
            selectedFileURL = nil
            NORDFUConstantsUtility.showAlert(message: "Selected file is not supported")
        }
    
        updateUploadButtonState()
    }
    
    func onFileTypeNotSelected() {
        selectedFileURL = nil
        updateUploadButtonState()
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
        
        
        let fileNameExtention = aFileURL.pathExtension.lowercased()
        
        if fileNameExtention == "zip" {
            selectedFirmware = DFUFirmware(urlToZipFile: aFileURL)
            if selectedFirmware != nil && selectedFirmware?.fileName != nil {
                fileName.text = selectedFirmware?.fileName
                let content = try? Data(contentsOf: aFileURL)
                fileSize.text = String(format: "%lu bytes", (content?.count)!)
                fileType.text = "Distribution packet (ZIP)"
            }else{
                selectedFirmware = nil
                selectedFileURL = nil
                NORDFUConstantsUtility.showAlert(message: "Seleted file is not supported")
            }
            self.updateUploadButtonState()
        }else{
            // Show a view to select the file type
            let mainStorybord                   = UIStoryboard(name: "Main", bundle: nil)
            let navigationController            = mainStorybord.instantiateViewController(withIdentifier: "SelectFileType")
            let filetTypeViewController         = navigationController.childViewControllerForStatusBarHidden as? NORFileTypeViewController
            filetTypeViewController!.delegate   = self
            self.present(navigationController, animated: true, completion:nil)
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
        self.clearUI()
    }

    //MARK: - DFUProgressDelegate
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        self.progress.progress = Float(progress) / 100.0
        progressLabel.text = String("\(progress)% (\(part)/\(totalParts))")
    }
    
    //MARK: - Segue Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if (segue.identifier == "scan") {
                // Set this contoller as scanner delegate
                let aNavigationController = segue.destination as? UINavigationController
                let scannerViewController = aNavigationController?.childViewControllerForStatusBarHidden as? NORScannerViewController
                scannerViewController?.delegate = self
            }else if segue.identifier == "FileSegue" {
                let aNavigationController = segue.destination as? UINavigationController
                let barViewController = aNavigationController?.childViewControllerForStatusBarHidden as? UITabBarController
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

    func applicationDidEnterBackgroundCallback() {
        if dfuController != nil {
            NORDFUConstantsUtility.showBackgroundNotification(message: "Uploading firmware...")
        }
    }
    
    func applicationDidBecomeActiveCallback() {
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
        DispatchQueue.main.async(execute: {
            self.dfuController        = nil
            self.selectedPeripheral   = nil

            self.deviceName.text      = "DEFAULT DFU"
            self.uploadStatus.text    = nil
            self.uploadStatus.isHidden  = true
            self.progress.progress    = 0.0
            self.progress.isHidden      = true
            self.progressLabel.text   = nil
            self.progressLabel.isHidden = true
            
            self.uploadButton.setTitle("Upload", for: UIControlState())
            self.updateUploadButtonState()
            self.enableOtherButtons()
            self.removeObservers()
        })
    }
    
    func performDFU() {
        self.disableOtherButtons()
        progress.isHidden = false
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
        dfuController = initiator.with(firmware: selectedFirmware!).start()
        uploadButton.setTitle("Cancel", for: UIControlState())
        uploadButton.isEnabled = true
    }

}
