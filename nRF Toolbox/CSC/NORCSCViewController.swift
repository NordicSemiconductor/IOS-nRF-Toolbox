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
    var cscServiceUUID                      : CBUUID
    var cscMeasurementCharacteristicUUID    : CBUUID
    var batteryServiceUUID                  : CBUUID
    var batteryLevelCharacteristicUUID      : CBUUID
    var oldWheelRevolution                  : Int?
    var oldCrankRevolution                  : Int?
    var travelDistance                      : Double?
    var oldWheelEventTime                   : Double?
    var totalTravelDistance                 : Double?
    var oldCrankEventTime                   : Double?
    var wheelCircumference                  : Double?
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
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        if cyclePeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(cyclePeripheral!)
        }
    }
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .csc))
    }

    //MARK: - UIViewController delegate
    required init?(coder aDecoder: NSCoder) {
        cscServiceUUID                   = CBUUID(string: NORServiceIdentifiers.cscServiceUUIDString)
        cscMeasurementCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cscMeasurementCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        verticalLabel.transform = CGAffineTransform(translationX: -150.0, y: 0.0).rotated(by: CGFloat(-M_PI_2))
        oldWheelEventTime = 0.0
        oldWheelRevolution = 0
        travelDistance = 0.0
        totalTravelDistance = 0.0
        oldCrankEventTime = 0
        oldCrankRevolution = 0
        wheelCircumference = UserDefaults.standard.double(forKey: "key_diameter")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if cyclePeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(cyclePeripheral!)
        }
        super.viewWillAppear(animated)
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != "scan" || cyclePeripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "scan" else {
            return
        }

        let navigationController = segue.destination
        let scannerViewController = navigationController.childViewControllerForStatusBarHidden as! NORScannerViewController
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
        aPeripheral.delegate = self;
        let options = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnConnectionKey as NSCopying)
        bluetoothManager!.connect(aPeripheral, options: options as? [String : AnyObject])
    }
    
    //MARK: - CentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Bluetooth powered off")
        } else {
            print("Bluetooth powered on")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async { 
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", for: UIControlState())
        }
        
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackgroundHandler), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActiveHandler), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        peripheral.discoverServices([cscServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        print("did fail to connect")
        DispatchQueue.main.async(execute: {
            NORAppUtilities.showAlert(title: "Error", andMessage:"Connecting to the peripheral failed. Try again")
            self.cyclePeripheral = nil
            self.clearUI()
        })
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected \(peripheral)")
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            if NORAppUtilities.isApplicationInactive() {
                let name = peripheral.name ?? "Peripheral"
                NORAppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
            }
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            
            self.cyclePeripheral = nil
            self.clearUI()
        })
    }
    
    //MARK: -  NORCSCViewController implementation
    func didEnterBackgroundHandler() {
        let name = cyclePeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    func didBecomeActiveHandler() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func clearUI() {
        connectionButton.setTitle("CONNECT", for: UIControlState())
        battery.setTitle("n/a", for: UIControlState.disabled)
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
    
    func decodeCSC(withData data : Data) {
        let value = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))
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
        } else {
            if flag & CRANK_REVOLUTION_FLAG == 2 {
                crankRevDiff = self.processCrankData(withData: data, andCrankRevolutionIndex: 1)
                if crankRevDiff > 0 {
                    ratio = wheelRevDiff / crankRevDiff
                    wheelToCrankRatio.text = String(format: "%.2f", ratio)
                }
            }
        }
    }
    
    func processWheelData(withData data :Data) -> Double {
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
        
        let value = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))
        
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
  
    func processCrankData(withData data : Data, andCrankRevolutionIndex index : Int) -> Double {
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
        
        let value = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))

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
        cadence.text = "\(travelCadence)"
        return crankRevolutionDiff
    }
    
    //MARK: - CBPeripheralDelegate methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService : CBService in peripheral.services! {
            if aService.uuid == cscServiceUUID {
                peripheral.discoverCharacteristics(nil, for: aService)
            } else if aService.uuid == batteryServiceUUID {
                peripheral.discoverCharacteristics(nil, for: aService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error occurred while discovering characteristic: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        if service.uuid == cscServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == cscMeasurementCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: aCharacteristic)
                }
            }
        } else if service.uuid == batteryServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == batteryLevelCharacteristicUUID {
                    peripheral.readValue(for: aCharacteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
            return
        }
        
        if characteristic.uuid == cscMeasurementCharacteristicUUID {
            DispatchQueue.main.async {
                self.decodeCSC(withData: characteristic.value!)
            }
        } else if characteristic.uuid == batteryLevelCharacteristicUUID {
            DispatchQueue.main.async {
                let array = UnsafeMutablePointer<UInt8>(OpaquePointer(((characteristic.value as NSData?)?.bytes)!))
                let batteryLevel = array[0]
                let text = "\(batteryLevel)%"
                self.battery.setTitle(text, for: UIControlState.disabled)
                if self.battery.tag == 0 {
                    if characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue > 0 {
                        self.battery.tag = 1
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }
    
}
