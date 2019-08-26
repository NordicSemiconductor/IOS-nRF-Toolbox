//
//  UARTViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class UARTViewController: UIViewController, BluetoothManagerDelegate, ScannerDelegate, UIPopoverPresentationControllerDelegate, ButtonConfigureDelegate, StoryboardInstantiable {
    
    //MARK: - View Properties
    var bluetoothManager    : BluetoothManager?
    var uartPeripheralName  : String?
    var buttonsCommands     : NSMutableArray?
    var buttonsHiddenStatus : NSMutableArray?
    var buttonsImageNames   : NSMutableArray?
    var buttonIcons         : NSArray
    var selectedButton      : UIButton?
    var logger              : LogViewController?
    var editMode            : Bool!

    //MARK: - View Actions
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        bluetoothManager?.cancelPeripheralConnection()
    }
    @IBAction func editButtonTapped(_ sender: AnyObject) {
        let currentEditMode = editMode!
        setEditMode(mode: !currentEditMode)
    }
    @IBAction func showLogButtonTapped(_ sender: AnyObject) {
        revealViewController().revealToggle(animated: true)
    }
    @IBAction func buttonTapped(_ sender: AnyObject){
        if editMode {
            selectedButton = sender as? UIButton;
            showPopoverOnButton()
        } else {
            let command = buttonsCommands![sender.tag-1]
            send(value: String(describing: command))
        }
    }

    //MARK: - View OUtlets
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var connectionButton: UIButton!
    
    //MARK: - UIViewControllerDelegate
    required init?(coder aDecoder: NSCoder) {
        buttonIcons = ["Stop","Play","Pause","FastForward","Rewind","End","Start","Shuffle","Record","Number_1",
        "Number_2","Number_3","Number_4","Number_5","Number_6","Number_7","Number_8","Number_9",]
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        verticalLabel.transform = CGAffineTransform(translationX: -(verticalLabel.frame.width/2) + (verticalLabel.frame.height / 2), y: 0.0).rotated(by: -.pi / 2);
        
        // Retrieve three arrays (icons names (NSString), commands (NSString), visibility(Bool)) from NSUserDefaults
        retrieveButtonsConfiguration()
        editMode = false
        
        // Configure the SWRevealViewController
        let revealViewController = self.revealViewController()
        if revealViewController != nil {
            view.addGestureRecognizer(revealViewController!.panGestureRecognizer())
            logger = revealViewController?.rearViewController as? LogViewController
        }
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // The 'scan' seque will be performed only if bluetoothManager == nil (if we are not connected already).
        return identifier != "scan" || bluetoothManager == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "scan" else {
            return
        }
        
        // Set this contoller as scanner delegate
        let nc = segue.destination as! UINavigationController
        let controller = nc.children.first as! ScannerViewController
        // controller.filterUUID = CBUUID.init(string: ServiceIdentifiers.uartServiceUUIDString)
        controller.delegate = self
    }
    
    //MARK: - UIPopoverPresentationCtonrollerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    //MARK: - ScannerViewDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = BluetoothManager(withManager: aManager)
        bluetoothManager!.delegate = self
        bluetoothManager!.logger = logger
        logger!.clearLog()
        
        if let name = aPeripheral.name {
            uartPeripheralName = name
            deviceName.text = name
        } else {
            uartPeripheralName = "device"
            deviceName.text = "No name"
        }
        connectionButton.setTitle("CANCEL", for: .normal)
        bluetoothManager!.connectPeripheral(peripheral: aPeripheral)
    }
    
    //MARK: - BluetoothManagerDelegate
    func peripheralReady() {
        print("Peripheral is ready")
    }
    
    func peripheralNotSupported() {
        print("Peripheral is not supported")
    }
    
    func didConnectPeripheral(deviceName aName: String?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async {
            self.logger!.bluetoothManager = self.bluetoothManager
            self.connectionButton.setTitle("DISCONNECT", for: .normal)
        
            //Following if condition display user permission alert for background notification
            if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))){
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert], categories: nil))
            }

            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }

    func didDisconnectPeripheral() {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async {
            self.logger!.bluetoothManager = nil
            self.connectionButton.setTitle("CONNECT", for: .normal)
            self.deviceName.text = "DEFAULT UART"
            
            if AppUtilities.isApplicationInactive() {
                AppUtilities.showBackgroundNotification(message: "Peripheral \(self.uartPeripheralName!) is disconnected")
            }

            self.uartPeripheralName = nil
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        bluetoothManager = nil
    }

    //MARK: - ButtonconfigureDelegate
    func didConfigureButton(_ aButton: UIButton, withCommand aCommand: String, andIconIndex index: Int, shouldHide hide: Bool) {
        let userDefaults = UserDefaults.standard
        let buttonTag = (selectedButton?.tag)!-1
        buttonsHiddenStatus![(selectedButton?.tag)!-1] = NSNumber(value: hide as Bool)
        
        userDefaults.set(buttonsHiddenStatus, forKey: "buttonsHiddenStatus")
        if hide == true {
            selectedButton?.setImage(nil, for: .normal)
        }else{
            let image = UIImage(named: buttonIcons[index] as! String)
            selectedButton?.setImage(image, for: .normal)
        }
        
        buttonsImageNames![buttonTag] = buttonIcons[index]
        buttonsCommands![buttonTag] = aCommand
        
        userDefaults.set(buttonsImageNames, forKey: "buttonsImageNames")
        userDefaults.set(self.buttonsCommands, forKey: "buttonsCommands")
        userDefaults.synchronize()
    }
    
    //MARK: - UArtViewController Implementation
    func retrieveButtonsConfiguration() {
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "buttonsCommands") != nil {
            //Buttons configurations already saved in NSUserDefaults
            buttonsCommands = NSMutableArray(array: userDefaults.object(forKey: "buttonsCommands") as! NSArray)
            buttonsHiddenStatus = NSMutableArray(array: userDefaults.object(forKey: "buttonsHiddenStatus") as! NSArray)
            buttonsImageNames   = NSMutableArray(array: userDefaults.object(forKey: "buttonsImageNames") as! NSArray)
             showButtonsWithSavedConfiguration()
        } else {
            //First time viewcontroller is loaded and there is no saved buttons configurations in NSUserDefaults
            //Setting up the default values for the first time
            buttonsCommands = NSMutableArray(array: ["","","","","","","","",""])
            buttonsHiddenStatus = NSMutableArray(array: [true,true,true,true,true,true,true,true,true])
            buttonsImageNames = NSMutableArray(array: ["Play","Play","Play","Play","Play","Play","Play","Play","Play"])
            userDefaults.set(buttonsCommands, forKey: "buttonsCommands")
            userDefaults.set(buttonsHiddenStatus, forKey: "buttonsHiddenStatus")
            userDefaults.set(buttonsImageNames, forKey: "buttonsImageNames")
            userDefaults.synchronize()
        }
    }
    
    func showButtonsWithSavedConfiguration() {
        for aButton: UIButton in buttons {
            if (buttonsHiddenStatus![aButton.tag - 1] as AnyObject).boolValue == true {
                aButton.backgroundColor = .nordicLightGray
                aButton.setImage(nil, for: .normal)
                aButton.isEnabled = false
            } else {
                aButton.backgroundColor = .nordicLake
                aButton.setImage(UIImage(named: buttonsImageNames![aButton.tag-1] as! String), for: .normal)
                aButton.isEnabled = true
            }
        }
    }
    
    func showPopoverOnButton() {
        let popOverViewController = storyboard?.instantiateViewController(withIdentifier: "StoryboardIDEditPopup") as! EditPopupViewController
        popOverViewController.delegate = self
        popOverViewController.isHidden = false
        popOverViewController.command = buttonsCommands![(selectedButton?.tag)!-1] as? String
        let buttonImageName = buttonsImageNames![(selectedButton?.tag)!-1]
        popOverViewController.setIconIndex(buttonIcons.index(of: buttonImageName))
        popOverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        popOverViewController.popoverPresentationController?.delegate = self
        present(popOverViewController, animated: true, completion: nil)

        popOverViewController.popoverPresentationController?.sourceView = self.view!
        popOverViewController.popoverPresentationController?.sourceRect = self.view.bounds
        popOverViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        popOverViewController.preferredContentSize = CGSize(width: 300.0, height: 300.0)
    }

    func setEditMode(mode aMode: Bool){
        editMode = aMode
        
        if aMode {
            editButton.setTitle("Done", for: .normal)
            for aButton : UIButton in buttons {
                aButton.backgroundColor = .nordicFall
                aButton.isEnabled = true
            }
        } else {
            editButton.setTitle("Edit", for: .normal)
            showButtonsWithSavedConfiguration()
        }
    }

    @objc func applicationDidEnterBackgroundCallback(){
        AppUtilities.showBackgroundNotification(message: "You are still connected to \(self.uartPeripheralName!)")
    }
    
    @objc func applicationDidBecomeActiveCallback(){
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    //MARK: - UART API
    func send(value aValue : String) {
        bluetoothManager?.send(text: aValue)
    }
}
