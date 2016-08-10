//
//  NORBMPViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 06/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORBPMViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate {
    
    //MARK: - ViewController Properties
    var bpmServiceUUID                                : CBUUID?
    var bpmBloodPressureMeasurementCharacteristicUUID : CBUUID?
    var bpmIntermediateCuffPressureCharacteristicUUID : CBUUID?
    var batteryServiceUUID                            : CBUUID?
    var batteryLevelCharacteristicUUID                : CBUUID?
    var bluetoothManager                              : CBCentralManager?
    var connectedPeripheral                           : CBPeripheral?
    
    //MARK: - Referencing Outlets
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var systolic: UILabel!
    @IBOutlet weak var systolicUnit: UILabel!
    @IBOutlet weak var diastolic: UILabel!
    @IBOutlet weak var diastolicUnit: UILabel!
    @IBOutlet weak var meanAp: UILabel!
    @IBOutlet weak var meanApUnit: UILabel!
    @IBOutlet weak var pulse: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    
    //MARK: - Referencing Actions
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        if connectedPeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .BPM))
    }

    //MARK: - UIViewController methods
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bpmServiceUUID                                = CBUUID(string: NORServiceIdentifiers.bpmServiceUUIDString)
        bpmBloodPressureMeasurementCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.bpmBloodPressureMeasurementCharacteristicUUIDString)
        bpmIntermediateCuffPressureCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.bpmIntermediateCuffPressureCharacteristicUUIDString)
        batteryServiceUUID                            = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID                = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-150.0, 0.0), CGFloat(-M_PI_2));
    }
    
    //MARK: - NORBPMViewController Implementation
    
    func didEnterBackgroundCallback(notification aNotification: NSNotification) {
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to peripheral \(connectedPeripheral?.name), the app will continue to collect data in the backrgound")
    }
    
    func didBecomeActiveCallback(notification aNotification: NSNotification) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func clearUI() {
        deviceName.text = "DEFAULT BPM"
        battery.tag = 0
        battery.setTitle("n/a", forState: UIControlState.Disabled)
        
        systolicUnit.hidden     = true
        diastolicUnit.hidden    = true
        meanApUnit.hidden       = true
        systolic.text           = "-"
        diastolic.text          = "-"
        meanAp.text             = "-"
        pulse.text              = "-"
        timestamp.text          = "-"
    }

    
    //MARK: - NORScannerDelegate methods
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        clearUI()
        bluetoothManager = aManager
        bluetoothManager?.delegate = self
        
        aPeripheral.delegate = self
        let connectionOptions = NSDictionary(object: NSNumber(bool: true), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey)
        bluetoothManager?.connectPeripheral(aPeripheral, options: connectionOptions as? [String : AnyObject])
    }
    
    //MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOff {
            print("Bluetooth powered off")
        }else{
            print("Bluetooth powered on")
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        dispatch_async(dispatch_get_main_queue()) {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
        }
        
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didEnterBackgroundCallback(notification:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didBecomeActiveCallback(notification:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        connectedPeripheral = peripheral
        peripheral.discoverServices([bpmServiceUUID!, batteryServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
            self.connectedPeripheral = nil
            self.clearUI()
        });
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
            self.connectedPeripheral = nil
            
            if NORAppUtilities.isApplicationInactive() {
                NORAppUtilities.showBackgroundNotification(message: "Peripheral \(peripheral.name) is isconnected")
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        })
    }

    //MARK: - CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print("Error discovering services, \(error?.localizedDescription)")
            bluetoothManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService : CBService in peripheral.services! {
            if aService.UUID == batteryServiceUUID {
                connectedPeripheral?.discoverCharacteristics([batteryLevelCharacteristicUUID!], forService: aService)
            }else if aService.UUID == bpmServiceUUID {
                connectedPeripheral?.discoverCharacteristics([bpmBloodPressureMeasurementCharacteristicUUID!,bpmIntermediateCuffPressureCharacteristicUUID!], forService: aService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if service.UUID == bpmServiceUUID {
            for aCharacteristic :CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == bpmBloodPressureMeasurementCharacteristicUUID ||
                    aCharacteristic.UUID == bpmIntermediateCuffPressureCharacteristicUUID {
                    peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
                }
            }
        } else if service.UUID == batteryServiceUUID {
            for aCharacteristic :CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID == batteryLevelCharacteristicUUID{
                    peripheral.readValueForCharacteristic(aCharacteristic)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            if characteristic.UUID == self.batteryLevelCharacteristicUUID {
                // Decode the characteristic data
                let data = characteristic.value;
                var pointer = UnsafeMutablePointer<UInt8>(data!.bytes)
                let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
                let text = String(format: "%d%%", batteryLevel)
                self.battery.setTitle(text, forState: UIControlState.Disabled)
                
                if self.battery.tag == 0 {
                    if characteristic.properties.rawValue & CBCharacteristicProperties.Notify.rawValue > 0 {
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                        self.battery.tag = 1
                    }
                }
            }else if characteristic.UUID == self.bpmBloodPressureMeasurementCharacteristicUUID ||
                characteristic.UUID == self.bpmIntermediateCuffPressureCharacteristicUUID {
                let data = characteristic.value
                var pointer = UnsafeMutablePointer<UInt8>(data!.bytes)
                let flags = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
                let kPA              : Bool = (flags & 0x01) > 0
                let timestampPresent : Bool = (flags & 0x02) > 0
                let pulseRatePresent : Bool = (flags & 0x04) > 0
                
                if kPA == true {
                    self.systolicUnit.text  = "kPa"
                    self.diastolicUnit.text = "kPa"
                    self.meanApUnit.text    = "kPa"
                } else {
                    self.systolicUnit.text  = "mmHg"
                    self.diastolicUnit.text = "mmHg"
                    self.meanApUnit.text    = "mmHg"
                }
                
                //Read main values
                if characteristic.UUID == self.bpmBloodPressureMeasurementCharacteristicUUID {
                    let systolicValue  = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    let diastolicValue = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    let meanApValue    = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    
                    self.systolic.text = String(format: "%.1f", systolicValue)
                    self.diastolic.text = String(format: "%.1f", diastolicValue)
                    self.meanAp.text = String(format: "%.1f", meanApValue)
                    
                    self.systolicUnit.hidden    = false
                    self.diastolicUnit.hidden   = false
                    self.meanApUnit.hidden      = false
                } else {
                    
                    let systolicValue = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    pointer += 4
                    
                    self.systolic.text = String(format: "%.1f", systolicValue)
                    self.diastolic.text = "n/a"
                    self.meanAp.text = "n/a"
                    
                    self.systolicUnit.hidden    = false
                    self.diastolicUnit.hidden   = true
                    self.meanApUnit.hidden      = true
                }
                
                // Read timestamp
                if timestampPresent {
                    let date = NORCharacteristicReader.readDateTime(ptr: &pointer)
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyy, hh:mm"
                    let dateformattedString = dateFormatter.stringFromDate(date)
                    self.timestamp.text = dateformattedString
                }else{
                    self.timestamp.text = "n/a"
                }

                // Read pulse
                if pulseRatePresent {
                    let pulseValue = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    self.pulse.text = String(format: "%.1f", pulseValue)
                }else{
                    self.pulse.text = "-"
                }
            }
        })
    }

    //MARK: - Segue handling
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            let nc = segue.destinationViewController as! UINavigationController
            let controller = nc.childViewControllerForStatusBarHidden() as! NORScannerViewController
            controller.filterUUID = bpmServiceUUID
            controller.delegate = self
        }
    }
}
