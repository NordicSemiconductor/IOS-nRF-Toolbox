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
    var selectedFileURL    : NSURL?


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
    
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        handleAboutButtonTapped()
    }
    @IBAction func uploadButtonTapped(sender: AnyObject) {
        handleUploadButtonTapped()
    }
    
    //MARK: - UIVIewControllerDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-145.0, 0.0), CGFloat(-M_PI_2))
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        //if DFU peripheral is connected and user press Back button then disconnect it
        if self.isMovingFromParentViewController() && dfuController != nil {
            dfuController?.abort()
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
            let content = NSData(contentsOfURL: selectedFileURL!)
            fileSize.text = String(format: "%d bytes", (content?.length)!)
            
            switch  aType {
            case .Application:
                fileType.text = "Application"
                break
            case .Bootloader:
                fileType.text = "Bootloader"
                break
            case .Softdevice:
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
    func onFileSelected(withURL aFileURL: NSURL) {
        selectedFileURL = aFileURL
        selectedFirmware = nil
        fileName.text = nil
        fileSize.text = nil
        fileType.text = nil
        
        
        let fileNameExtention = aFileURL.pathExtension!.lowercaseString
        
        if fileNameExtention == "zip" {
            selectedFirmware = DFUFirmware(urlToZipFile: aFileURL)
            if selectedFirmware != nil && selectedFirmware?.fileName != nil {
                fileName.text = selectedFirmware?.fileName
                let content = NSData(contentsOfURL: aFileURL)
                fileSize.text = String(format: "%lu bytes", (content?.length)!)
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
            let navigationController            = mainStorybord.instantiateViewControllerWithIdentifier("SelectFileType")
            let filetTypeViewController         = navigationController.childViewControllerForStatusBarHidden() as? NORFileTypeViewController
            filetTypeViewController!.delegate   = self
            self.presentViewController(navigationController, animated: true, completion:nil)
        }

    }
    //MARK: - LoggerDelegate
    func logWith(level:LogLevel, message:String){
        var levelString : String?
        switch(level) {
            case .Application:
                levelString = "Application"
                break
            case .Debug:
                levelString = "Debug"
                break
            case .Error:
                levelString = "Error"
                break
            case .Info:
                levelString = "Info"
                break
            case .Verbose:
                levelString = "Verbose"
                break
            case .Warning:
                levelString = "Warning"
        }
        print("\(levelString!): \(message)")
    }

    //MARK: - DFUServiceDelegate
    func didStateChangedTo(state: DFUState) {
        
        switch state {
            case .Connecting:
                uploadStatus.text = "Connecting..."
                break
            case .Starting:
                uploadStatus.text = "Starting DFU..."
                break
            case .EnablingDfuMode:
                uploadStatus.text = "Enabling DFU Bootloader..."
                break
            case .Uploading:
                uploadStatus.text = "Uploading..."
                break
            case .Validating:
                uploadStatus.text = "Validating..."
                break
            case .Disconnecting:
                uploadStatus.text = "Disconnecting..."
                break
            case .Completed:
                NORDFUConstantsUtility.showAlert(message: "Upload complete")
                if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
                    NORDFUConstantsUtility.showBackgroundNotification(message: "Upload complete")
                }
                self.clearUI()
                break
            case .Aborted:
                NORDFUConstantsUtility.showAlert(message: "Upload aborted")
                if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded(){
                    NORDFUConstantsUtility.showBackgroundNotification(message: "Upload aborted")
                }
                self.clearUI()
                break
        }
    }
    func didErrorOccur(error: DFUError, withMessage message: String) {
        print("Error : \(error): \(message)")
        NORDFUConstantsUtility.showAlert(message: message)
        if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
            NORDFUConstantsUtility.showBackgroundNotification(message: message)
        }
        clearUI()
    }

    //MARK: - DFUProgressDelegate
    func onUploadProgress(part: Int, totalParts: Int, progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        self.progress.progress = Float(progress) / 100.0
        progressLabel.text = String("\(progress)% (\(part)/\(totalParts))")
    }
    
    //MARK: - Segue Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            if (segue.identifier == "scan") {
                // Set this contoller as scanner delegate
                let aNavigationController = segue.destinationViewController as? UINavigationController
                let scannerViewController = aNavigationController?.childViewControllerForStatusBarHidden() as? NORScannerViewController
                scannerViewController?.delegate = self
            }else if segue.identifier == "FileSegue" {
                let aNavigationController = segue.destinationViewController as? UINavigationController
                let barViewController = aNavigationController?.childViewControllerForStatusBarHidden() as? UITabBarController
                let appFilecsVC = barViewController?.viewControllers?.first as? NORAppFilesViewController
                appFilecsVC?.fileDelegate = self
                let userFilesVC = barViewController?.viewControllers?.last as? NORAppFilesViewController
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
        
        let alert = UIAlertController(title: "Abort?", message: "Do you want to abort?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let abort = UIAlertAction(title: "Abort", style: .Destructive, handler: { (anAction) in
            self.dfuController?.abort()
            alert.dismissViewControllerAnimated(true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Default, handler: { (anAction) in
            self.dfuController?.resume()
            alert.dismissViewControllerAnimated(true, completion: nil)
        })
        
        alert.addAction(abort)
        alert.addAction(cancel)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func registerObservers() {
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert], categories: nil))
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: UIApplicationDidBecomeActiveNotification, object: nil)
        }
    }
    func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    func applicationDidEnterBackgroundCallback() {
        if dfuController != nil {
            NORDFUConstantsUtility.showBackgroundNotification(message: "Uploading firmware...")
        }
    }
    
    func applicationDidBecomeActiveCallback() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }

    func updateUploadButtonState() {
        uploadButton.enabled = selectedFirmware != nil && selectedFirmware != nil
    }
    
    func disableOtherButtons() {
        selectFileButton.enabled = false
        connectButton.enabled = false
    }
    
    func enableOtherButtons() {
        selectFileButton.enabled = true
        connectButton.enabled = true
    }
    
    func clearUI() {
        dfuController        = nil
        selectedPeripheral   = nil
        
        deviceName.text      = "DEFAULT DFU"
        uploadStatus.text    = nil
        uploadStatus.hidden  = true
        progress.progress    = 0.0
        progress.hidden      = true
        progressLabel.text   = nil
        progressLabel.hidden = true
        
        uploadButton.setTitle("Upload", forState: UIControlState.Normal)
        self.updateUploadButtonState()
        self.enableOtherButtons()
        self.removeObservers()
    }
    
    func performDFU() {
        self.disableOtherButtons()
        progress.hidden = false
        progressLabel.hidden = false
        uploadStatus.hidden = false
        uploadButton.enabled = false
        
        self.registerObservers()
        
        // To start the DFU operation the DFUServiceInitiator must be used
        let initiator = DFUServiceInitiator(centralManager: centralManager!, target: selectedPeripheral!)
        initiator.withFirmwareFile(selectedFirmware!)
        initiator.forceDfu = NSUserDefaults.standardUserDefaults().valueForKey("dfu_force_dfu")!.boolValue
        initiator.packetReceiptNotificationParameter = UInt16((NSUserDefaults.standardUserDefaults().valueForKey("dfu_number_of_packets")?.intValue)!)
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self
        dfuController = initiator.start()
        uploadButton.setTitle("Cancel", forState: UIControlState.Normal)
        uploadButton.enabled = true
    }

}
