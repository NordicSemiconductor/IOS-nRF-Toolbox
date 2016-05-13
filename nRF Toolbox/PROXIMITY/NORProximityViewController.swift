//
//  NORPRoximityViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 10/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

class NORProximityViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, CBPeripheralManagerDelegate {
    
    //MARK: - Class Properties
    var bluetoothManager                        : CBCentralManager?
    var proximityImmediateAlertServiceUUID      : CBUUID?
    var proximityLinkLossServiceUUID            : CBUUID?
    var proximityAlertLevelCharacteristicUUID   : CBUUID?
    var batteryServiceUUID                      : CBUUID?
    var batteryLevelCharacteristicUUID          : CBUUID?
    var isImmidiateAlertOn                      : Bool?
    var isBackButtonPressed                     : Bool?
    var proximityPeripheral                     : CBPeripheral?
    var peripheralManager                       : CBPeripheralManager?
    var immidiateAlertCharacteristic            : CBCharacteristic?
    var audioPlayer                             : AVAudioPlayer?

    //MARK: - View Outlets
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var findmeButton: UIButton!
    @IBOutlet weak var connectionButton: UIButton!
    
    //MARK: - View Actions
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        if proximityPeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(proximityPeripheral!)
        }
    }
    
    @IBAction func findmeButtonTapped(sender: AnyObject) {
        if self.immidiateAlertCharacteristic != nil {
            if isImmidiateAlertOn == true {
                self.immidiateAlertOff()
            } else {
                self.immidiateAlertOn()
            }
        }
    }
    
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.showAbout(message: AppUtilities.getProximityHelpText())
    }

    
    //MARK: - UIVIew Delegate
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Custom initialization
        proximityImmediateAlertServiceUUID      = CBUUID(string:proximityImmediateAlertServiceUUIDString)
        proximityLinkLossServiceUUID            = CBUUID(string: proximityLinkLossServiceUUIDString)
        proximityAlertLevelCharacteristicUUID   = CBUUID(string:proximityAlertLevelCharacteristicUUIDString)
        batteryServiceUUID                      = CBUUID(string:batteryServiceUUIDString)
        batteryLevelCharacteristicUUID          = CBUUID(string:batteryLevelCharacteristicUUIDString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-110.0, 0.0), CGFloat(-M_PI_2))
        self.immidiateAlertCharacteristic = nil
        isImmidiateAlertOn = false
        isBackButtonPressed = false;
        self.initGattServer()
        self.initSound()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if proximityPeripheral != nil && isBackButtonPressed == true {
            bluetoothManager?.cancelPeripheralConnection(proximityPeripheral!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - Class Implementation
    func initSound() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
            print("Could not init AudioSession!")
            return
        }

        let url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("high", ofType: "mp3")!)
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: url)
        } catch _ {
            print("Could not intialize AudioPlayer")
            return
        }
        audioPlayer?.prepareToPlay()
    }
    
    func enableFindmeButton() {
        findmeButton.enabled         = true
        findmeButton.backgroundColor = UIColor.blackColor()
        findmeButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }
    
    func disableFindmeButton() {
        findmeButton.enabled = false
        findmeButton.backgroundColor = UIColor.lightGrayColor()
        findmeButton.setTitleColor(UIColor.lightTextColor(), forState: UIControlState.Normal)
    }

    func initGattServer() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func addServices() {
        let service = CBMutableService(type: CBUUID(string:"1802"), primary: true)
        let characteristic = self.createCharacteristic()
        service.characteristics = [characteristic]
        self.peripheralManager?.addService(service)
    }
        
    func createCharacteristic() -> CBMutableCharacteristic {
        let properties : CBCharacteristicProperties  = CBCharacteristicProperties.WriteWithoutResponse
        let permissions : CBAttributePermissions     = CBAttributePermissions.Writeable
        let characteristicType : CBUUID              = CBUUID(string:"2A06")
        let characteristic : CBMutableCharacteristic = CBMutableCharacteristic(type: characteristicType, properties: properties, value: nil, permissions: permissions)
        
        return characteristic
    }

    func immidiateAlertOn() {
        if self.immidiateAlertCharacteristic != nil {
            var val : UInt8 = 2
            let data = NSData(bytes: &val, length: 1)
            proximityPeripheral?.writeValue(data, forCharacteristic: immidiateAlertCharacteristic!, type: CBCharacteristicWriteType.WithoutResponse)
            isImmidiateAlertOn = true
            findmeButton.setTitle("SilentMe", forState: UIControlState.Normal)
        }
    }
    
    func immidiateAlertOff() {
        if self.immidiateAlertCharacteristic != nil {
            var val : UInt8 = 0
            let data = NSData(bytes: &val, length: 1)
            proximityPeripheral?.writeValue(data, forCharacteristic: immidiateAlertCharacteristic!, type: CBCharacteristicWriteType.WithoutResponse)
            isImmidiateAlertOn = false
            findmeButton.setTitle("FindMe", forState: UIControlState.Normal)
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
    func playLoopingSound() {
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.play()
    }
    
    func playSoundOnce() {
        audioPlayer?.play()
    }

    func clearUI() {
        deviceName.text = "DEFAULT PROXIMITY"
        battery.setTitle("n/a", forState:UIControlState.Disabled)
        battery.tag = 0
        lockImage.highlighted = false
        isImmidiateAlertOn = false
        self.immidiateAlertCharacteristic = nil
    }

    func applicationDidEnterBackgroundCallback() {
        AppUtilities.showBackgroundNotification("You are still connected to \(proximityPeripheral?.name)")
    }
    
    func applicationDidBecomeActiveCallback() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }

    //MARK: - Segue Methods
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier != "scan" || proximityPeripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc = segue.destinationViewController as! UINavigationController
            let controller = nc.childViewControllerForStatusBarHidden() as! NORScannerViewController
            controller.filterUUID = proximityLinkLossServiceUUID
            controller.delegate = self
        }
    }
    
    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager
        bluetoothManager!.delegate = self
        
        // The sensor has been selected, connect to it
        proximityPeripheral = aPeripheral
        proximityPeripheral!.delegate = self
        bluetoothManager?.connectPeripheral(proximityPeripheral!, options: [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(bool:true)])
    }
    
    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
        } else {
            print("Bluetooth not ON")
        }
    }
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
            self.lockImage.highlighted = true
            self.enableFindmeButton()
        })
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))){
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: UIApplicationDidBecomeActiveNotification, object: nil)
        if AppUtilities.isApplicationStateInactiveORBackground() {
            AppUtilities.showBackgroundNotification("\(self.proximityPeripheral?.name) is within range!")
        }
        
        self.proximityPeripheral?.discoverServices([proximityLinkLossServiceUUID!, proximityImmediateAlertServiceUUID!, batteryServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            AppUtilities.showAlert("Error", alertMessage: "Connecting to the peripheral failed. Try again")
            self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
            self.proximityPeripheral = nil
            self.disableFindmeButton()
            self.clearUI()
        })
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Peripheral disconnected or out of range!")
        dispatch_async(dispatch_get_main_queue(), {
            let message = "\(self.proximityPeripheral?.name) is out of range!"
            if error != nil {
                print("Error while disconnecting or link loss")
                self.lockImage.highlighted = false
                self.disableFindmeButton()
                self.bluetoothManager?.connectPeripheral(self.proximityPeripheral!, options: [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(bool:true)])
                if AppUtilities.isApplicationStateInactiveORBackground() {
                    AppUtilities.showBackgroundNotification(message)
                }else{
                    AppUtilities.showAlert("PROXIMITY", alertMessage: message)
                }
                self.playSoundOnce()
            }else{
                self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
                if AppUtilities.isApplicationStateInactiveORBackground() {
                    AppUtilities.showBackgroundNotification("Peripheral \(peripheral.name)  is disconnected")
                }
                
                self.proximityPeripheral = nil
                self.clearUI()
                NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object: nil)
                NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
            }
        })
    }

    //MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for aService : CBService in (peripheral.services)! {
            if aService.UUID == CBUUID(string: "1803") {
                print("Link loss service is found")
                proximityPeripheral?.discoverCharacteristics([CBUUID(string: "2A06")], forService: aService)
            } else if aService.UUID == CBUUID(string: "1802") {
                print("Immediate alert service is found")
                proximityPeripheral?.discoverCharacteristics([CBUUID(string: "2A06")], forService: aService)
            }else if aService.UUID == batteryServiceUUID {
                print("Battery service is found")
                proximityPeripheral?.discoverCharacteristics(nil, forService: aService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if service.UUID == CBUUID(string:"1803") {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == CBUUID(string: "2A06"){
                    var val = UInt8(1)
                    let data = NSData(bytes: &val, length: 1)
                    proximityPeripheral?.writeValue(data, forCharacteristic: aCharacteristic, type: CBCharacteristicWriteType.WithResponse)
                }
            }
        } else if service.UUID == CBUUID(string:"1802") {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == CBUUID(string: "2A06"){
                    immidiateAlertCharacteristic = aCharacteristic
                }
            }
        } else if service.UUID == batteryServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == batteryLevelCharacteristicUUID {
                    proximityPeripheral?.readValueForCharacteristic(aCharacteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            print("Error while reading battery value")
            return
        }
        print(characteristic.UUID)
        dispatch_async(dispatch_get_main_queue(), {
            if characteristic.UUID == self.batteryLevelCharacteristicUUID {
                let value = characteristic.value!
                let array = UnsafeMutablePointer<UInt8>(value.bytes)
                let batteryLevel = UInt8(array[0])
                let text = String(format:"%d%%", batteryLevel)
                self.battery.setTitle(text, forState: UIControlState.Disabled)

                if self.battery.tag == 0 {
                    // If battery level notifications are available, enable them
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.Notify.rawValue) > 0 {
                        //Mark that we have enabled notifications
                        self.battery.tag = 1
                        //Enable notification on data characteristic
                        self.proximityPeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
            }
        })
    }
    //MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch (peripheral.state) {
        case CBPeripheralManagerState.PoweredOff:
            print("PeripheralManagerState is Off")
            break;
        case CBPeripheralManagerState.PoweredOn:
            print("PeripheralManagerState is on");
            self.addServices()
            break;
        default:
            break;
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        guard error == nil else {
            print("Error while adding peripheral service")
            return
        }
        print("PeripheralManager added sercvice successfulyy")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        let attributeRequest = requests[0]
        
        if attributeRequest.characteristic.UUID == CBUUID(string: "2A06") {
           let data        = attributeRequest.value!
           let array       = UnsafeMutablePointer<UInt8>(data.bytes)
           let alertLevel  = array[0]

            switch alertLevel {
            case 0:
                print("No Alert")
                stopSound()
                break
            case 1:
                print("Low Alert")
                playLoopingSound()
                break
            case 2:
                print("High Alert")
                playSoundOnce()
                break
            default:
                break
                
            }
        }

    }
}
