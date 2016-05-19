//
//  NORHTSViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 09/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORHTSViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate {

    //MARK: - ViewController properties
    var bluetoothManager                 : CBCentralManager?
    var connectedPeripheral              : CBPeripheral?
    var htsServiceUUID                   : CBUUID?
    var htsMeasurementCharacteristicUUID : CBUUID?
    var batteryServiceUUID               : CBUUID?
    var batteryLevelCharacteristicUUID   : CBUUID?
    var temperatureValueFahrenheit       : Bool?
    var temperatureValue                 : Double?

    //MARK: - ViewController outlets
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var connectionButon: UIButton!
    @IBOutlet weak var temperatureUnit: UILabel!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var degreeControl: UISegmentedControl!
   
    //MARK: - ViewControllerActions
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .HTM))
    }
    
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        if connectedPeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    
    @IBAction func degreeHasChanged(sender: AnyObject) {
        let control = sender as! UISegmentedControl
        if (control.selectedSegmentIndex == 0)
        {
            // Celsius
            temperatureValueFahrenheit = false
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "fahrenheit")
            self.temperatureUnit.text = "°C"
            temperatureValue = (temperatureValue! - 32.0) * 5.0 / 9.0
        }
        else
        {
            // Fahrenheit
            temperatureValueFahrenheit = true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "fahrenheit")
            self.temperatureUnit.text = "°F"
            temperatureValue = temperatureValue! * 9.0 / 5.0 + 32.0;
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if connectedPeripheral != nil {
            self.temperature.text = String(format:"%.2f", temperatureValue!)
        }

    }

    //MARK: - Segue handling
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let navigationController = segue.destinationViewController as! UINavigationController
            let scannerController    = navigationController.childViewControllerForStatusBarHidden() as! NORScannerViewController
            scannerController.filterUUID = htsServiceUUID
            scannerController.delegate = self
        }
    }

    //MARK: - UIViewControllerDelegate
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Custom initialization
        htsServiceUUID                   = CBUUID(string: NORServiceIdentifiers.htsServiceUUIDString)
        htsMeasurementCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.htsMeasurementCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-185.0, 0.0), CGFloat(-M_PI_2))
        self.updateUnits()
    }

    //MARK: - CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else
        {
            print("Error discovering service: %@", error?.localizedDescription)
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
            return;
        }
        
        for aService : CBService in peripheral.services! {
            // Discovers the characteristics for a given service
            if aService.UUID == htsServiceUUID {
                connectedPeripheral?.discoverCharacteristics([htsMeasurementCharacteristicUUID!], forService: aService)
            }else if aService.UUID == batteryServiceUUID {
                connectedPeripheral?.discoverCharacteristics([batteryLevelCharacteristicUUID!], forService: aService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {

        // Characteristics for one of those services has been found
        
        if service.UUID == htsServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == htsMeasurementCharacteristicUUID {
                    // Enable notification on data characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
                    break
                }
            }
        } else if service.UUID == batteryServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == batteryLevelCharacteristicUUID {
                    peripheral.readValueForCharacteristic(aCharacteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            // Decode the characteristic data
            let data = characteristic.value
            var array = UnsafeMutablePointer<UInt8>((data?.bytes)!)
            
            if characteristic.UUID == self.batteryLevelCharacteristicUUID {
                let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &array)
                
                let text = String(format: "%d%%", batteryLevel)
                self.battery.setTitle(text, forState: UIControlState.Disabled)
                
                if self.battery.tag == 0 {
                    // If battery level notifications are available, enable them
                    if characteristic.properties.rawValue & CBCharacteristicProperties.Notify.rawValue > 0 {
                        self.battery.tag = 1; // mark that we have enabled notifications
                        
                        // Enable notification on data characteristic
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
            }else if characteristic.UUID == self.htsMeasurementCharacteristicUUID {
                let flags = NORCharacteristicReader.readUInt8Value(ptr: &array)
                let tempInFahrenheit : Bool = (flags & 0x01) > 0
                let timestampPresent : Bool = (flags & 0x02) > 0
                let typePresent      : Bool = (flags & 0x04) > 0
                
                var tempValue        : Float = NORCharacteristicReader.readFloatValue(ptr: &array)
                if tempInFahrenheit == false && self.temperatureValueFahrenheit! == true {
                    tempValue = tempValue * 9.0 / 5.0 + 32.0
                }
                if tempInFahrenheit == true && self.temperatureValueFahrenheit == false {
                    tempValue = (tempValue - 32.0) * 5.0 / 9.0
                }
                
                self.temperatureValue = Double(tempValue)
                self.temperature.text = String(format: "%.2f", tempValue)
                
                if timestampPresent == true {
                    let date = NORCharacteristicReader.readDateTime(ptr: &array)
                    let dateFormat = NSDateFormatter()
                    dateFormat.dateFormat = "dd.MM.yyyy, hh:mm"
                    
                    let dateFormattedString = dateFormat.stringFromDate(date)
                    self.timestamp.text = dateFormattedString
                } else {
                    self.timestamp.text = "Date n/a"
                }
                
                /* temperature type */
                if typePresent == true {
                    let type = NORCharacteristicReader.readUInt8Value(ptr: &array)
                    var location : NSString = ""
                    
                    switch (type)
                    {
                    case 0x01:
                        location = "Armpit";
                        break;
                    case 0x02:
                        location = "Body - general";
                        break;
                    case 0x03:
                        location = "Ear";
                        break;
                    case 0x04:
                        location = "Finger";
                        break;
                    case 0x05:
                        location = "Gastro-intenstinal Tract";
                        break;
                    case 0x06:
                        location = "Mouth";
                        break;
                    case 0x07:
                        location = "Rectum";
                        break;
                    case 0x08:
                        location = "Toe";
                        break;
                    case 0x09:
                        location = "Tympanum - ear drum";
                        break;
                    default:
                        location = "Unknown";
                        break;
                    }
                    self.type.text = String(format: "Location: %@", location)
                }
                else
                {
                    self.type.text = "Location: n/a";
                }
                
                if  NORAppUtilities.isApplicationInactive()
                {
                    var message : String = ""
                    if (self.temperatureValueFahrenheit == true) {
                        message = String(format:"New temperature reading: %.2f°F", tempValue)
                    } else {
                        message = String(format:"New temperature reading: %.2f°C", tempValue)
                    }
                    
                    NORAppUtilities.showBackgroundNotification(message: message)
                }
            }
            })
    }
    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state != CBCentralManagerState.PoweredOn {
            print("Bluetooth not porwerd on!")
        }
    }
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.deviceName.text = peripheral.name
            self.connectionButon.setTitle("DISCONNECT", forState: UIControlState.Normal)
        })

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didEnterBackrgoundCallback), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didBecomeActiveCallback), name: UIApplicationDidBecomeActiveNotification, object: nil)

        // Peripheral has connected. Discover required services
        connectedPeripheral = peripheral;
        peripheral.discoverServices([htsServiceUUID!, batteryServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButon.setTitle("CONNECT", forState: UIControlState.Normal)
            self.connectedPeripheral = nil
            self.clearUI()
        })
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.connectionButon.setTitle("CONNECT", forState: UIControlState.Normal)
            if NORAppUtilities.isApplicationInactive() {
                NORAppUtilities.showBackgroundNotification(message: "Peripheral \(peripheral.name) is disconnected")
            }
            self.connectedPeripheral = nil
            self.clearUI()
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        })
    }
    
    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager
        bluetoothManager?.delegate = self
        
        // The sensor has been selected, connect to it
        aPeripheral.delegate = self
        let options = [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(bool:true)]
        bluetoothManager?.connectPeripheral(aPeripheral, options: options)
    }
    
    //MARK: - NORHTSViewController implementation
    func updateUnits() {
        temperatureValueFahrenheit = NSUserDefaults.standardUserDefaults().boolForKey("fahrenheit")
        if temperatureValueFahrenheit == true {
            degreeControl.selectedSegmentIndex = 1
            self.temperature.text = "°F"
        } else {
            degreeControl.selectedSegmentIndex = 0
            self.temperature.text = "°C"
        }
    }
    
    func didEnterBackrgoundCallback() {
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(connectedPeripheral?.name) peripheral. It will collect data also in background.")
    }
    
    func didBecomeActiveCallback() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        self.updateUnits()
    }
    
    func clearUI() {
        deviceName.text = "DEFAULT HTM"
        battery.tag = 0
        battery.setTitle("n/a", forState: UIControlState.Disabled)
        self.temperature.text = "-"
        self.timestamp.text = ""
        self.type.text = ""
    }
}
