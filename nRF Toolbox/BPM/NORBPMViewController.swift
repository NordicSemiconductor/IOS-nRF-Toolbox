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
    var bpmServiceUUID                                : CBUUID
    var bpmBloodPressureMeasurementCharacteristicUUID : CBUUID
    var bpmIntermediateCuffPressureCharacteristicUUID : CBUUID
    var batteryServiceUUID                            : CBUUID
    var batteryLevelCharacteristicUUID                : CBUUID
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
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        if connectedPeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .bpm))
    }

    //MARK: - UIViewController methods
    required init?(coder aDecoder: NSCoder) {
        bpmServiceUUID                                = CBUUID(string: NORServiceIdentifiers.bpmServiceUUIDString)
        bpmBloodPressureMeasurementCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.bpmBloodPressureMeasurementCharacteristicUUIDString)
        bpmIntermediateCuffPressureCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.bpmIntermediateCuffPressureCharacteristicUUIDString)
        batteryServiceUUID                            = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID                = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verticalLabel.transform = CGAffineTransform(translationX: -150.0, y: 0.0).rotated(by: CGFloat(-M_PI_2));
    }
    
    //MARK: - NORBPMViewController Implementation
    
    func didEnterBackgroundCallback(notification aNotification: Notification) {
        let name = connectedPeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    func didBecomeActiveCallback(notification aNotification: Notification) {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func clearUI() {
        deviceName.text = "DEFAULT BPM"
        battery.tag = 0
        battery.setTitle("n/a", for: UIControlState.disabled)
        
        systolicUnit.isHidden     = true
        diastolicUnit.isHidden    = true
        meanApUnit.isHidden       = true
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
        let connectionOptions = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)
        bluetoothManager?.connect(aPeripheral, options: connectionOptions as? [String : AnyObject])
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
        DispatchQueue.main.async {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", for: UIControlState())
        }
        
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackgroundCallback(notification:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActiveCallback(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        connectedPeripheral = peripheral
        peripheral.discoverServices([bpmServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButton.setTitle("CONNECT", for: UIControlState())
            self.connectedPeripheral = nil
            self.clearUI()
        });
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            self.connectionButton.setTitle("CONNECT", for: UIControlState())
            self.connectedPeripheral = nil
            
            if NORAppUtilities.isApplicationInactive() {
                let name = peripheral.name ?? "Peripheral"
                NORAppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
            }
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        })
    }

    //MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService : CBService in peripheral.services! {
            if aService.uuid == batteryServiceUUID {
                peripheral.discoverCharacteristics([batteryLevelCharacteristicUUID], for: aService)
            } else if aService.uuid == bpmServiceUUID {
                peripheral.discoverCharacteristics(
                    [bpmBloodPressureMeasurementCharacteristicUUID,bpmIntermediateCuffPressureCharacteristicUUID],
                    for: aService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error occurred while discovering characteristic: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        if service.uuid == bpmServiceUUID {
            for aCharacteristic :CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == bpmBloodPressureMeasurementCharacteristicUUID ||
                    aCharacteristic.uuid == bpmIntermediateCuffPressureCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: aCharacteristic)
                }
            }
        } else if service.uuid == batteryServiceUUID {
            for aCharacteristic :CBCharacteristic in service.characteristics! {
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
            if characteristic.uuid == self.batteryLevelCharacteristicUUID {
                // Decode the characteristic data
                let data = characteristic.value;
                var pointer = UnsafeMutablePointer<UInt8>(mutating: (data! as NSData).bytes.bindMemory(to: UInt8.self, capacity: data!.count))
                let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &pointer)
                let text = "\(batteryLevel)%"
                self.battery.setTitle(text, for: UIControlState.disabled)
                
                if self.battery.tag == 0 {
                    if characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue > 0 {
                        peripheral.setNotifyValue(true, for: characteristic)
                        self.battery.tag = 1
                    }
                }
            } else if characteristic.uuid == self.bpmBloodPressureMeasurementCharacteristicUUID ||
                characteristic.uuid == self.bpmIntermediateCuffPressureCharacteristicUUID {
                let data = characteristic.value
                var pointer = UnsafeMutablePointer<UInt8>(mutating: (data! as NSData).bytes.bindMemory(to: UInt8.self, capacity: data!.count))
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
                if characteristic.uuid == self.bpmBloodPressureMeasurementCharacteristicUUID {
                    let systolicValue  = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    let diastolicValue = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    let meanApValue    = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    
                    self.systolic.text = String(format: "%.1f", systolicValue)
                    self.diastolic.text = String(format: "%.1f", diastolicValue)
                    self.meanAp.text = String(format: "%.1f", meanApValue)
                    
                    self.systolicUnit.isHidden    = false
                    self.diastolicUnit.isHidden   = false
                    self.meanApUnit.isHidden      = false
                } else {
                    let systolicValue = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    pointer += 4
                    
                    self.systolic.text = String(format: "%.1f", systolicValue)
                    self.diastolic.text = "n/a"
                    self.meanAp.text = "n/a"
                    
                    self.systolicUnit.isHidden    = false
                    self.diastolicUnit.isHidden   = true
                    self.meanApUnit.isHidden      = true
                }
                
                // Read timestamp
                if timestampPresent {
                    let date = NORCharacteristicReader.readDateTime(ptr: &pointer)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyy, hh:mm"
                    let dateformattedString = dateFormatter.string(from: date)
                    self.timestamp.text = dateformattedString
                } else {
                    self.timestamp.text = "n/a"
                }

                // Read pulse
                if pulseRatePresent {
                    let pulseValue = NORCharacteristicReader.readSFloatValue(ptr: &pointer)
                    self.pulse.text = String(format: "%.1f", pulseValue)
                } else {
                    self.pulse.text = "-"
                }
            }
        })
    }

    //MARK: - Segue handling
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            let nc = segue.destination as! UINavigationController
            let controller = nc.childViewControllerForStatusBarHidden as! NORScannerViewController
            controller.filterUUID = bpmServiceUUID
            controller.delegate = self
        }
    }
}
