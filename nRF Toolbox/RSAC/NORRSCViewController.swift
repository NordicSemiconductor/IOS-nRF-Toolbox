//
//  NORRSCViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 10/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORRSCViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate {

    //MARK: - Class properties
    var bluetoothManager    : CBCentralManager?
    var connectedPeripheral : CBPeripheral?
    var timer               : NSTimer? //The timer is used to periodically update strides number
    var stepsNumber         : UInt32?  //Number of steps counted during the current connection session. Calculated based on cadence and time intervals
    var cadenceValue        : UInt8?   //Number of steps counted during the current connection session. Calculated based on cadence and time intervals
    var stripLength         : UInt8?   //The last strip length obtained from the device
    var tripDistance        : UInt32?  //Trip distance, since connection established, in [cm]. Calculated with each step. If stride length is not present it equals UINT32_MAX.
    var isBackButtonPressed : Bool?
    
    //UUIDs
    var rscMeasurementCharacteristicUUID : CBUUID?
    var batteryServiceUUID               : CBUUID?
    var batteryLevelCharacteristicUUID   : CBUUID?
    var rscServiceUUID                   : CBUUID?
    
    //MARK: - UIView Outlets
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var speed: UILabel!
    @IBOutlet weak var cadence: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var totalDistance: UILabel!
    @IBOutlet weak var strides: UILabel!
    @IBOutlet weak var activity: UILabel!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var distanceUnit: UILabel!
    @IBOutlet weak var totalDistanceUnit: UILabel!

    
    //MARK: - UIView Actions
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        if connectedPeripheral != nil
        {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .RSC))
    }

    //MARK: - UIViewDelegate
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        stepsNumber                      = 0
        tripDistance                     = 0
        rscServiceUUID                   = CBUUID(string:rscServiceUUIDString)
        rscMeasurementCharacteristicUUID = CBUUID(string:rscMeasurementCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string:batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string:batteryLevelCharacteristicUUIDString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-170.0, 0.0), CGFloat(-M_PI_2))
        isBackButtonPressed = false
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        if connectedPeripheral != nil && isBackButtonPressed==true
        {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - Segue methods
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc = segue.destinationViewController as! UINavigationController
            let scanController = nc.childViewControllerForStatusBarHidden() as! NORScannerViewController
            scanController.filterUUID = rscServiceUUID
            scanController.delegate = self
        }
    }
    //MARK: - NORRSCViewController implementation
    func timerFired(timer aTimer : NSTimer) {
        // Here we will update the stride count.
        // If a device has been disconnected, abort. There is nothing to do.
        guard connectedPeripheral != nil else {
            print("Peripheral not connected, stopping timer")
            aTimer.invalidate()
            return
        }

        stepsNumber = stepsNumber! + 1
        self.strides.text = String(format:"%d", stepsNumber!)
        
        // If stride length has been set, calculate the trip distance
        if stripLength > 0 {
            tripDistance = tripDistance! + UInt32(stripLength!)

            let tripDistanceinKilometers = Double(tripDistance! / 100000) // Convert from Centimeters
            let tripDistanceinMeters     = Double(tripDistance! / 100)    // Convert from Centimeters
            if tripDistanceinKilometers < 1 {
                self.distance.text = String(format:"%.0f", tripDistanceinMeters)
                self.distanceUnit.text = "m"
            }
            else
            {
                self.distance.text = String(format:"%.2f", tripDistanceinKilometers)
                self.distanceUnit.text = "km"
            }
        } else {
            if tripDistance == 0 {
                self.distance.text = "n/a"
            }
        }
        
        // If cadence is greater than 0 we have to reschedule the timer with new time interval
        if cadenceValue > 0 {
            let timeInterval = NSTimeInterval(65.0 / Float(cadenceValue!)) // 60 second + 5 for calibration
            timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(self.timerFired(timer:)), userInfo: nil, repeats: false)
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    func applicationDidEnterBackgroundCallback() {
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(connectedPeripheral?.name). It will collect data in the background")
    }
    
    func applicationDidBecomeActiveCallback() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func clearUI() {
        stepsNumber = 0;
        tripDistance = 0
        cadenceValue = 0
        timer = nil
        deviceName.text = "DEFAULT RSC"
        battery.tag = 0
        battery.setTitle("n/a", forState: UIControlState.Disabled)
        speed.text = "-"
        cadence.text = "-"
        distance.text = "-"
        totalDistance.text = "-"
        strides.text = "-"
        activity.text = "n/a"
    }
    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // TODO
        }else{
            print("Bluetooth not powered ON!")
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
        })
        
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))){
         //[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert], categories: nil))
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: UIApplicationDidBecomeActiveNotification, object: nil)

        // Peripheral has connected. Discover required services
        connectedPeripheral = peripheral
        peripheral.discoverServices([rscServiceUUID!, batteryServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
            self.connectedPeripheral = nil
            self.clearUI()
        })
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
            if NORAppUtilities.isApplicationInactive(){
                NORAppUtilities.showBackgroundNotification(message: "Peripheral \(peripheral.name) is disconnected")
            }
            self.connectedPeripheral = nil
            self.clearUI()
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        })
    }
    
    //MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print("Error discovering service: \(error?.localizedDescription)")
            bluetoothManager?.cancelPeripheralConnection(peripheral)
            return
        }

        for aService : CBService in peripheral.services! {
            // Discovers the characteristics for a given service
            if aService.UUID == rscServiceUUID {
                connectedPeripheral?.discoverCharacteristics([rscMeasurementCharacteristicUUID!], forService: aService)
            }else if aService.UUID == batteryServiceUUID {
                connectedPeripheral?.discoverCharacteristics([batteryLevelCharacteristicUUID!], forService: aService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // Characteristics for one of those services has been found
        if service.UUID == rscServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == rscMeasurementCharacteristicUUID {
                    peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
                    break
                }
            }
        } else if service.UUID == batteryServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == batteryLevelCharacteristicUUID {
                    peripheral.readValueForCharacteristic(aCharacteristic)
                    break
                }
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            // Decode the characteristic data
            let data = characteristic.value
            var array = UnsafeMutablePointer<UInt8>(data!.bytes)
            
            if characteristic.UUID == self.batteryLevelCharacteristicUUID! {
                let batteryLevel = CharacteristicReader.readUInt8Value(&array)
                let text = String(format:"%d%%", batteryLevel)
                self.battery.setTitle(text , forState: UIControlState.Disabled)

                if self.battery.tag == 0 {
                    // If battery level notifications are available, enable them
                    if characteristic.properties.rawValue & CBCharacteristicProperties.Notify.rawValue > 0 {
                        self.battery.tag = 1
                        // Enable notification on data characteristic
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
            }else if characteristic.UUID == self.rscMeasurementCharacteristicUUID! {
                let flags = CharacteristicReader.readUInt8Value(&array)
                let strideLengthPresent  = (flags & 0x01) > 0
                let totalDistancePresent = (flags & 0x02) > 0
                let running              = (flags & 0x04) > 0
                if running == true {
                    self.activity.text = "RUNNING"
                }else{
                    self.activity.text = "WALKING"
                }
                let speedValue = Float(CharacteristicReader.readUInt16Value(&array)) / 256.0 * 3.6
                self.speed.text = String(format:"%.1f", speedValue)
                
                self.cadenceValue = CharacteristicReader.readUInt8Value(&array)
                self.cadence.text = String(format:"%d", self.cadenceValue!)
                
                // If user started to walk, we have to initialize the timer that will increase strides counter
                if self.cadenceValue! > 0 && self.timer == nil {
                    self.strides.text = String(format: "%d", self.stepsNumber!)
                    let timeInterval = 65.0 / Double(self.cadenceValue!) // 60 seconds + 5 for calibration
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(self.timerFired(timer:)), userInfo: nil, repeats: false)
                }

                if strideLengthPresent == true {
                    self.stripLength = CharacteristicReader.readUInt8Value(&array) // value in Centimeters
                }
                
                if totalDistancePresent == true {
                    let distanceValue = CharacteristicReader.readUInt32Value(&array) //value in Centimeters
                    let distanceValueInKilometers = Double(distanceValue / 10000)
                    let distanceValueInMeters = Double(distanceValue / 10)
                    if distanceValueInKilometers < 1 {
                        self.totalDistance.text = String(format:"%.0f", distanceValueInMeters)
                        self.totalDistanceUnit.text = "m"
                    }else{
                        self.totalDistance.text = String(format:"%.0f", distanceValueInKilometers)
                        self.totalDistanceUnit.text = "Km"
                    }
                }else{
                    self.totalDistance.text = "n/a"
                }
            }
        })
    }
    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager
        bluetoothManager!.delegate = self
        // The sensor has been selected, connect to it
        aPeripheral.delegate = self
        bluetoothManager?.connectPeripheral(aPeripheral, options: [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(bool: true)])
    }
}
