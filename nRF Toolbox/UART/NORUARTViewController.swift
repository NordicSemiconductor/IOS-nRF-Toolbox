//
//  NORUARTViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORUARTViewController: UIViewController, NORBluetoothManagerDelegate, NORScannerDelegate, UIPopoverPresentationControllerDelegate, ButtonConfigureDelegate {
    
    //MARK: - View Properties
    var bluetoothManager    : NORBluetoothManager?
    var uartPeripheralName  : String?
    var buttonsCommands     : NSMutableArray?
    var buttonsHiddenStatus : NSMutableArray?
    var buttonsImageNames   : NSMutableArray?
    var buttonIcons         : NSArray?
    var selectedButton      : UIButton?
    var logger              : NORLogViewController?
    var editMode            : Bool?

    //MARK: - View Actions
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        bluetoothManager?.cancelPeriphralConnection()
    }
    @IBAction func editButtonTapped(sender: AnyObject) {
        let currentEditMode = editMode!
        setEditMode(mode: !currentEditMode)
    }
    @IBAction func showLogButtonTapped(sender: AnyObject) {
        self.revealViewController().revealToggleAnimated(true)
    }
    @IBAction func buttonTapped(sender: AnyObject){
        if editMode == true
        {
            self.selectedButton = sender as? UIButton;
            self.showPopoverOnButton()
        }
        else
        {
            let command = buttonsCommands![sender.tag-1]
            self.send(value: String(command))
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
        super.init(coder: aDecoder)
        buttonIcons = ["Stop","Play","Pause","FastForward","Rewind","End","Start","Shuffle","Record","Number_1",
        "Number_2","Number_3","Number_4","Number_5","Number_6","Number_7","Number_8","Number_9",]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-20.0, 0.0), CGFloat(-M_PI_2));
        
        // Retrieve three arrays (icons names (NSString), commands (NSString), visibility(Bool)) from NSUserDefaults
        retrieveButtonsConfiguration()
        editMode = false
        
        // Configure the SWRevealViewController
        let revealViewController = self.revealViewController()
        if revealViewController != nil {
            self.view.addGestureRecognizer((revealViewController?.panGestureRecognizer())!)
            logger = revealViewController?.rearViewController as? NORLogViewController
        }
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // The 'scan' seque will be performed only if bluetoothManager == nil (if we are not connected already).
        return identifier != "scan" || self.bluetoothManager == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "scan" else {
            return
        }
        
        // Set this contoller as scanner delegate
        let nc = segue.destinationViewController as! UINavigationController
        let controller = nc.childViewControllerForStatusBarHidden() as! NORScannerViewController
        controller.delegate = self
    }
    
    //MARK: - UIPopoverPresentationCtonrollerDelegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    //MARK: - NORScannerViewDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = NORBluetoothManager(withManager: aManager)
        bluetoothManager?.delegate = self
        bluetoothManager?.logger = logger
        bluetoothManager?.connectPeripheral(peripheral: aPeripheral)
    }
    //MARK: - BluetoothManagerDelegate
    func peripheralReady() {
        print("Peripheral is ready")
    }
    func peripheralNotSupported() {
        print("Peripheral is not supported")
    }
    
    func didConnectPeripheral(deviceName aName: String) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.logger!.bluetoothManager = self.bluetoothManager
            self.uartPeripheralName = aName
            self.deviceName.text = aName
            self.connectionButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
            
        })
        
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))){
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert], categories: nil))
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    func didDisconnectPeripheral() {
            // Scanner uses other queue to send events. We must edit UI in the main queue
            dispatch_async(dispatch_get_main_queue(), {
                self.logger!.bluetoothManager = nil
                self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
                self.deviceName.text = "DEFAULT UART"
                
                if NORAppUtilities.isApplicationInactive() {
                    NORAppUtilities.showBackgroundNotification(message: "Peripheral \(self.uartPeripheralName) is disconnected")
                }

                self.uartPeripheralName = nil
            })
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        bluetoothManager = nil
    }

    //MARK: - ButtonconfigureDelegate
    func didConfigureButton(aButton: UIButton, withCommand aCommand: String, andIconIndex index: Int, shouldHide hide: Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let buttonTag = (selectedButton?.tag)!-1
        buttonsHiddenStatus![(selectedButton?.tag)!-1] = NSNumber(bool:hide)
        
        userDefaults.setObject(buttonsHiddenStatus, forKey: "buttonsHiddenStatus")
        if hide == true {
            selectedButton?.setImage(nil, forState: UIControlState.Normal)
        }else{
            let image = UIImage(named: buttonIcons![index] as! String)
            selectedButton?.setImage(image, forState: UIControlState.Normal)
        }
        
        buttonsImageNames![buttonTag] = buttonIcons![index]
        buttonsCommands![buttonTag] = aCommand
        
        userDefaults.setObject(buttonsImageNames, forKey: "buttonsImageNames")
        userDefaults.setObject(self.buttonsCommands, forKey: "buttonsCommands")
        userDefaults.synchronize()
    }
    //MARK: - NORUArtViewController Implementation
    func retrieveButtonsConfiguration() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey("buttonsCommands") != nil {
            //Buttons configurations already saved in NSUserDefaults
            buttonsCommands = NSMutableArray(array: userDefaults.objectForKey("buttonsCommands") as! NSArray)
            buttonsHiddenStatus = NSMutableArray(array: userDefaults.objectForKey("buttonsHiddenStatus") as! NSArray)
            buttonsImageNames   = NSMutableArray(array: userDefaults.objectForKey("buttonsImageNames") as! NSArray)
            self.showButtonsWithSavedConfiguration()
        } else {
            //First time viewcontroller is loaded and there is no saved buttons configurations in NSUserDefaults
            //Setting up the default values for the first time
            self.buttonsCommands = NSMutableArray(array: ["","","","","","","","",""])
            self.buttonsHiddenStatus = NSMutableArray(array: [true,true,true,true,true,true,true,true,true])
            self.buttonsImageNames = NSMutableArray(array: ["Play","Play","Play","Play","Play","Play","Play","Play","Play"])
            userDefaults.setObject(buttonsCommands, forKey: "buttonsCommands")
            userDefaults.setObject(buttonsHiddenStatus, forKey: "buttonsHiddenStatus")
            userDefaults.setObject(buttonsImageNames, forKey: "buttonsImageNames")
            userDefaults.synchronize()
        }
    }
    
    func showButtonsWithSavedConfiguration() {
        for aButton : UIButton in buttons! {
            if buttonsHiddenStatus![aButton.tag-1].boolValue == true {
                aButton.backgroundColor = UIColor(red: 200.0/255.0, green: 200.0/255.0, blue: 200.0/255.0, alpha: 1.0)
                aButton.setImage(nil, forState: UIControlState.Normal)
                aButton.enabled = false
            }else{
                aButton.backgroundColor = UIColor(red: 0.0/255.0, green:156.0/255.0, blue:222.0/255.0, alpha: 1.0)
                aButton.setImage(UIImage(named: buttonsImageNames![aButton.tag-1] as! String), forState: UIControlState.Normal)
                aButton.enabled = true
            }
        }
    }
    
    func showPopoverOnButton() {
        let popOverViewController = storyboard?.instantiateViewControllerWithIdentifier("StoryboardIDEditPopup") as! NOREditPopupViewController
        popOverViewController.delegate = self
        popOverViewController.isHidden = false
        popOverViewController.command = buttonsCommands![(selectedButton?.tag)!-1] as? String
        let buttonImageName = buttonsImageNames![(selectedButton?.tag)!-1]
        popOverViewController.setIconIndex((buttonIcons?.indexOfObject(buttonImageName))!)
        popOverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
        popOverViewController.popoverPresentationController?.delegate = self
        self.presentViewController(popOverViewController, animated: true, completion: nil)

        popOverViewController.popoverPresentationController?.sourceView = self.view!
        popOverViewController.popoverPresentationController?.sourceRect = self.view.bounds
        popOverViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        popOverViewController.preferredContentSize = CGSizeMake(300.0, 300.0)
    }

    func setEditMode(mode aMode : Bool){
        editMode = aMode
        
        if editMode == true {
            editButton.setTitle("Done", forState: UIControlState.Normal)
            for aButton : UIButton in buttons {
                aButton.backgroundColor = UIColor(red: 222.0/255.0, green: 74.0/266.0, blue: 19.0/255.0, alpha: 1.0)
                aButton.enabled = true
            }
        } else {
            editButton.setTitle("Edit", forState: UIControlState.Normal)
            showButtonsWithSavedConfiguration()
        }
    }

    func applicationDidEnterBackgroundCallback(){
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(uartPeripheralName)")
    }
    
    func applicationDidBecomeActiveCallback(){
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    //MARK: - UART API
    func send(value aValue : String) {
        if self.bluetoothManager != nil {
            bluetoothManager?.send(text: aValue)
        }
    }
}
