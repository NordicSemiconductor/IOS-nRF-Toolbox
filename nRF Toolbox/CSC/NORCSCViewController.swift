//
//  NORCSCViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 09/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORCSCViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate {

    //MARK: - ViewController properties
    let WHEEL_REVOLUTION_FLAG               : UInt8 = 0x01
    let CRANK_REVOLUTION_FLAG               : UInt8 = 0x02
    var bluetoothManager                    : CBCentralManager?
    var cscServiceUUID                      : CBUUID?
    var cscMeasurementCharacteristicUUID    : CBUUID?
    var batteryServiceUUID                  : CBUUID?
    var batteryLevelCharacteristicUUID      : CBUUID?
    var oldWheelRevolution                  : Int?
    var oldCrankRevolution                  : Int?
    var travelDistance                      : Double?
    var oldWheelEventTime                   : Double?
    var totalTravelDistance                 : Double?
    var oldCrankEventTime                   : Double?
    var wheelCircumference                  : Double?
    var isBackButtonPressed                 : Bool?
    var cyclePeripheral                     : CBPeripheral?

    //MARK: - ViewController Outlets
    @IBOutlet weak var battery              : UIButton!
    @IBOutlet weak var verticalLabel        : UILabel!
    @IBOutlet weak var deviceName           : UILabel!
    @IBOutlet weak var connectionButton     : UIButton!
    @IBOutlet weak var speed                : UILabel!
    @IBOutlet weak var cadence              : UILabel!
    @IBOutlet weak var distance             : UILabel!
    @IBOutlet weak var totalDistance        : UILabel!
    @IBOutlet weak var wheelToCrankRatio    : UILabel!
    
    //MARK: - ViewController Actions
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        if cyclePeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(cyclePeripheral!)
        }
    }
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.showAbout(message: AppUtilities.getCSCHelpText())
    }

    //MARK: - UIViewController delegate
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cscServiceUUID = CBUUID(string: cscServiceUUIDString)
        cscMeasurementCharacteristicUUID = CBUUID(string: cscMeasurementCharacteristicUUIDString)
        batteryServiceUUID = CBUUID(string: batteryServiceUUIDString)
        batteryLevelCharacteristicUUID = CBUUID(string:batteryLevelCharacteristicUUIDString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-150.0, 0.0), CGFloat(-M_PI_2))
        oldWheelEventTime = 0.0
        oldWheelRevolution = 0
        travelDistance = 0.0
        totalTravelDistance = 0.0
        oldCrankEventTime = 0
        oldCrankRevolution = 0
        isBackButtonPressed = true
        wheelCircumference = NSUserDefaults.standardUserDefaults().valueForKey("key_diameter")?.doubleValue
    }
    
    override func viewWillDisappear(animated: Bool) {
        if cyclePeripheral != nil && isBackButtonPressed == true {
            bluetoothManager?.cancelPeripheralConnection(cyclePeripheral!)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isBackButtonPressed = true
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return identifier != "scan" || cyclePeripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "scan" else {
            return
        }

        let navigationController = segue.destinationViewController
        let scannerViewController = navigationController.childViewControllerForStatusBarHidden() as! NORScannerViewController
        scannerViewController.filterUUID = cscServiceUUID
        scannerViewController.delegate = self
    }
    
    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager
        bluetoothManager!.delegate = self
        
        // The sensor has been selected, connect to it
        cyclePeripheral = aPeripheral;
        cyclePeripheral!.delegate = self;
        let options = NSDictionary(object: NSNumber(bool: true), forKey: CBConnectPeripheralOptionNotifyOnConnectionKey)
        bluetoothManager?.connectPeripheral(cyclePeripheral!, options: options as? [String : AnyObject])
    }
    
    //MARK: - CentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn{
        }else{
            print("Bluetooth is not porewed on!")
        }
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue()) { 
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
        }
        
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didEnterBackgroundHandler), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didBecomeActiveHandler), name: UIApplicationDidBecomeActiveNotification, object: nil)
        cyclePeripheral?.discoverServices([cscServiceUUID!, batteryServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        print("did fail to connect")
        dispatch_async(dispatch_get_main_queue(), {
            AppUtilities.showAlert("Error", alertMessage:"Connecting to the peripheral failed. Try again")
            self.cyclePeripheral = nil
            self.clearUI()
        })
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected \(peripheral)")
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            if AppUtilities.isApplicationStateInactiveORBackground() {
                AppUtilities.showBackgroundNotification(String(format: "%@ is disconnected", peripheral.name!))
            }
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
            
            self.cyclePeripheral = nil
            self.clearUI()
        })
    }
    
    //MARK: -  NORCSCViewController implementation
    func didEnterBackgroundHandler() {
        AppUtilities.showBackgroundNotification("You are still connected to \(cyclePeripheral!.name), it will collect data in the background")
    }
    
    func didBecomeActiveHandler() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func clearUI() {
        connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
        battery.setTitle("n/a", forState: UIControlState.Disabled)
        deviceName.text         = "DEFAULT CSC"
        battery.tag             = 0
        speed.text              = "-"
        cadence.text            = "-"
        distance.text           = "-"
        totalDistance.text      = "-"
        wheelToCrankRatio.text  = "-"
        oldWheelEventTime       = 0.0
        oldWheelRevolution      = 0
        oldCrankEventTime       = 0.0
        oldCrankRevolution      = 0
        travelDistance          = 0
        totalTravelDistance     = 0
    }
    
    func decodeCSC(withData data : NSData) {

        let value = UnsafeMutablePointer<UInt8>(data.bytes)
        var wheelRevDiff :Double = 0
        var crankRevDiff :Double = 0
        var ratio        :Double = 0
        let flag = value[0]
        
        if flag & WHEEL_REVOLUTION_FLAG == 1 {
            wheelRevDiff = self.processWheelData(withData: data)
            if flag & 0x02 == 2 {
                crankRevDiff = self.processCrankData(withData: data, andCrankRevolutionIndex: 7)
                if crankRevDiff > 0 {
                    ratio = wheelRevDiff / crankRevDiff
                    wheelToCrankRatio.text = String(format: "%.2f", ratio)
                }
            }
        }else{
            if flag & CRANK_REVOLUTION_FLAG == 2 {
                self.processCrankData(withData: data, andCrankRevolutionIndex: 1)
            }
        }
    }
    
    func processWheelData(withData data :NSData) -> Double {
        /* wheel Revolution Data Present
         * 4 bytes (1 to 4) uint32 are Cummulative Wheel Revolutions
         * next 2 bytes (5 to 6) uint16 are Last Wheel Event Time in seconds and
         * Last Wheel Event Time unit has resolution of 1/1024 seconds
         */
        
        var wheelRevolution     :UInt8  = 0
        var wheelEventTime      :Double = 0
        var wheelRevolutionDiff :Double = 0
        var wheelEventTimeDiff  :Double = 0
        var travelSpeed         :Double = 0
        
        let value = UnsafeMutablePointer<UInt8>(data.bytes)
        
        wheelRevolution = UInt8(CFSwapInt32LittleToHost(UInt32(value[1])))
        wheelEventTime  = Double((UInt16(value[6]) * 0xFF) + UInt16(value[5]))
        if oldWheelRevolution != 0 {
            wheelRevolutionDiff = Double(wheelRevolution) - Double(oldWheelRevolution!)
            travelDistance = travelDistance! + ((wheelRevolutionDiff * wheelCircumference!)/1000.0)
            totalTravelDistance = (Double(wheelRevolution) * Double(wheelCircumference!)) / 1000.0
        }
        if oldWheelEventTime != 0 {
            wheelEventTimeDiff = wheelEventTime - oldWheelEventTime!
        }
        if wheelEventTimeDiff > 0 {
            wheelEventTimeDiff = wheelEventTimeDiff / 1024.0
            //convert speed from m/s to km/h by multiplying 3.6
            travelSpeed = (((wheelRevolutionDiff * wheelCircumference!) / wheelEventTimeDiff) * 3.6)
            speed.text = String(format: "%.2f", travelSpeed)
            distance.text = String(format: "%.2f", travelDistance!)
            totalDistance.text = String(format: "%.2f", totalTravelDistance!)
        }
        
        oldWheelRevolution = Int(wheelRevolution)
        oldWheelEventTime = wheelEventTime
        
        return wheelRevolutionDiff
    }
  
    func processCrankData(withData data : NSData, andCrankRevolutionIndex index : Int) -> Double {
        /* Crank Revolution data present
         * if Wheel Revolution data present then
         * Crank Revolution data starts from index 7 else from index 1
         * 2 bytes uint16 are Cummulative Crank Revolutions
         * next 2 bytes uint16 are Last Crank Event time in seconds and
         * Last Crank Event Time unit has a resolution of 1/1024 seconds
         */

        var crankEventTime      : Double = 0
        var crankRevolutionDiff : Double = 0
        var crankEventTimeDiff  : Double = 0
        var crankRevolution     : Int    = 0
        var travelCadence       : Int    = 0
        
        let value = UnsafeMutablePointer<UInt8>(data.bytes)

        crankRevolution = Int(CFSwapInt16LittleToHost(UInt16(value[index])))
        crankEventTime  = Double((UInt16(value[index+3]) * 0xFF) + UInt16(value[index+2]))+1.0

        if oldCrankEventTime != 0 {
            crankEventTimeDiff = crankEventTime - oldCrankEventTime!
        }
        
        if oldCrankRevolution != 0 {
            crankRevolutionDiff = Double(crankRevolution - oldCrankRevolution!)
        }

        if crankEventTimeDiff > 0 {
            crankEventTimeDiff = crankEventTimeDiff / 1024.0
            travelCadence = Int(Double(crankRevolutionDiff / crankEventTimeDiff) * Double(60))
        }
        
        oldCrankRevolution = crankRevolution
        oldCrankEventTime = crankEventTime
        cadence.text = String(format: "%d", travelCadence)
        return crankRevolutionDiff
    }
    
    //MARK: - CBPeripheralDelegate methods
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print(String(format:"error in discovering services on device: %@", (cyclePeripheral?.name)!))
            return
        }
        for aService : CBService in peripheral.services! {
            if aService.UUID == cscServiceUUID {
                cyclePeripheral?.discoverCharacteristics(nil, forService: aService)
            }else if aService.UUID == batteryServiceUUID {
                cyclePeripheral?.discoverCharacteristics(nil, forService: aService)
            }
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard error == nil else {
            print(String(format:"error in discovering characteristic on device: %@",(cyclePeripheral?.name)!))
            return
        }
        if service.UUID == cscServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == cscMeasurementCharacteristicUUID{
                    cyclePeripheral?.setNotifyValue(true, forCharacteristic: aCharacteristic)
                }
            }
        } else if service.UUID == batteryServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == batteryLevelCharacteristicUUID{
                    cyclePeripheral?.readValueForCharacteristic(aCharacteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            print("Error while updating CSC value")
            return
        }
        if characteristic.UUID == cscMeasurementCharacteristicUUID {
            dispatch_async(dispatch_get_main_queue()) {
                self.decodeCSC(withData: characteristic.value!)
            }
        }else if characteristic.UUID == batteryLevelCharacteristicUUID {
            dispatch_async(dispatch_get_main_queue()) {
                let array = UnsafeMutablePointer<UInt8>((characteristic.value?.bytes)!)
                let batteryLevel = array[0]
                let text = String(format: "%d%%", batteryLevel)
                self.battery.setTitle(text, forState: UIControlState.Disabled)
                if self.battery.tag == 0{
                    if characteristic.properties.rawValue & CBCharacteristicProperties.Notify.rawValue > 0 {
                        self.battery.tag = 1
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
            }
        }
    }
    
}
