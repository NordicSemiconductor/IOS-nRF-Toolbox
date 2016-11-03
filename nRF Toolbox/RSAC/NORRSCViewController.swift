//
//  NORRSCViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 10/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class NORRSCViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate {

    //MARK: - Class properties
    var bluetoothManager    : CBCentralManager?
    var connectedPeripheral : CBPeripheral?
    var timer               : Timer? //The timer is used to periodically update strides number
    var stepsNumber         : UInt32?  //Number of steps counted during the current connection session. Calculated based on cadence and time intervals
    var cadenceValue        : UInt8?   //Number of steps counted during the current connection session. Calculated based on cadence and time intervals
    var stripLength         : UInt8?   //The last strip length obtained from the device
    var tripDistance        : UInt32?  //Trip distance, since connection established, in [cm]. Calculated with each step. If stride length is not present it equals UINT32_MAX.
    var isBackButtonPressed : Bool?
    
    //UUIDs
    var rscMeasurementCharacteristicUUID : CBUUID
    var batteryServiceUUID               : CBUUID
    var batteryLevelCharacteristicUUID   : CBUUID
    var rscServiceUUID                   : CBUUID
    
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
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        if connectedPeripheral != nil
        {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .rsc))
    }

    //MARK: - UIViewDelegate
    required init?(coder aDecoder: NSCoder) {
        stepsNumber                      = 0
        tripDistance                     = 0
        rscServiceUUID                   = CBUUID(string: NORServiceIdentifiers.rscServiceUUIDString)
        rscMeasurementCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.rscMeasurementCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        self.verticalLabel.transform = CGAffineTransform(translationX: -170.0, y: 0.0).rotated(by: CGFloat(-M_PI_2))
        isBackButtonPressed = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if connectedPeripheral != nil && isBackButtonPressed==true
        {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - Segue methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc = segue.destination as! UINavigationController
            let scanController = nc.childViewControllerForStatusBarHidden as! NORScannerViewController
            scanController.filterUUID = rscServiceUUID
            scanController.delegate = self
        }
    }
    //MARK: - NORRSCViewController implementation
    func timerFired(timer aTimer : Timer) {
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
            let timeInterval = TimeInterval(65.0 / Float(cadenceValue!)) // 60 second + 5 for calibration
            timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.timerFired(timer:)), userInfo: nil, repeats: false)
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func applicationDidEnterBackgroundCallback() {
        let name = connectedPeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    func applicationDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func clearUI() {
        stepsNumber = 0;
        tripDistance = 0
        cadenceValue = 0
        timer = nil
        deviceName.text = "DEFAULT RSC"
        battery.tag = 0
        battery.setTitle("n/a", for: UIControlState.disabled)
        speed.text = "-"
        cadence.text = "-"
        distance.text = "-"
        totalDistance.text = "-"
        strides.text = "-"
        activity.text = "n/a"
    }
    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Bluetooth powered off")
        } else {
            print("Bluetooth powered on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", for: UIControlState())
        })
        
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))){
         //[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert], categories: nil))
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        // Peripheral has connected. Discover required services
        connectedPeripheral = peripheral
        peripheral.discoverServices([rscServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButton.setTitle("CONNECT", for: UIControlState())
            self.connectedPeripheral = nil
            self.clearUI()
        })
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            self.connectionButton.setTitle("CONNECT", for: UIControlState())
            if NORAppUtilities.isApplicationInactive() {
                let name = peripheral.name ?? "Peripheral"
                NORAppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
            }
            self.connectedPeripheral = nil
            self.clearUI()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        })
    }
    
    //MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return;
        }
        
        for aService : CBService in peripheral.services! {
            // Discovers the characteristics for a given service
            if aService.uuid == rscServiceUUID {
                connectedPeripheral?.discoverCharacteristics([rscMeasurementCharacteristicUUID], for: aService)
            }else if aService.uuid == batteryServiceUUID {
                connectedPeripheral?.discoverCharacteristics([batteryLevelCharacteristicUUID], for: aService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error occurred while discovering characteristic: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        // Characteristics for one of those services has been found
        if service.uuid == rscServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == rscMeasurementCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: aCharacteristic)
                    break
                }
            }
        } else if service.uuid == batteryServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == batteryLevelCharacteristicUUID {
                    peripheral.readValue(for: aCharacteristic)
                    break
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
            return
        }
        
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            // Decode the characteristic data
            let data = characteristic.value
            var array = UnsafeMutablePointer<UInt8>(mutating: (data! as NSData).bytes.bindMemory(to: UInt8.self, capacity: data!.count))
            
            if characteristic.uuid == self.batteryLevelCharacteristicUUID {
                let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &array)
                let text = "\(batteryLevel)%"
                self.battery.setTitle(text , for: UIControlState.disabled)

                if self.battery.tag == 0 {
                    // If battery level notifications are available, enable them
                    if characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue > 0 {
                        self.battery.tag = 1
                        // Enable notification on data characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            } else if characteristic.uuid == self.rscMeasurementCharacteristicUUID {
                let flags = NORCharacteristicReader.readUInt8Value(ptr: &array)
                let strideLengthPresent  = (flags & 0x01) > 0
                let totalDistancePresent = (flags & 0x02) > 0
                let running              = (flags & 0x04) > 0
                if running == true {
                    self.activity.text = "RUNNING"
                } else {
                    self.activity.text = "WALKING"
                }
                let speedValue = Float(NORCharacteristicReader.readUInt16Value(ptr: &array)) / 256.0 * 3.6
                self.speed.text = String(format:"%.1f", speedValue)
                
                self.cadenceValue = NORCharacteristicReader.readUInt8Value(ptr: &array)
                self.cadence.text = String(format:"%d", self.cadenceValue!)
                
                // If user started to walk, we have to initialize the timer that will increase strides counter
                if self.cadenceValue! > 0 && self.timer == nil {
                    self.strides.text = String(format: "%d", self.stepsNumber!)
                    let timeInterval = 65.0 / Double(self.cadenceValue!) // 60 seconds + 5 for calibration
                    self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.timerFired(timer:)), userInfo: nil, repeats: false)
                }

                if strideLengthPresent == true {
                    self.stripLength = NORCharacteristicReader.readUInt8Value(ptr: &array) // value in Centimeters
                }
                
                if totalDistancePresent == true {
                    let distanceValue = NORCharacteristicReader.readUInt32Value(ptr: &array) //value in Centimeters
                    let distanceValueInKilometers = Double(distanceValue / 10000)
                    let distanceValueInMeters = Double(distanceValue / 10)
                    if distanceValueInKilometers < 1 {
                        self.totalDistance.text = String(format:"%.0f", distanceValueInMeters)
                        self.totalDistanceUnit.text = "m"
                    } else {
                        self.totalDistance.text = String(format:"%.0f", distanceValueInKilometers)
                        self.totalDistanceUnit.text = "Km"
                    }
                } else {
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
        bluetoothManager?.connect(aPeripheral, options: [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(value: true as Bool)])
    }
}
