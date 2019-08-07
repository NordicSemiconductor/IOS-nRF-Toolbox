//
//  NORBGMViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 29/04/16.
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


class NORBGMViewController: NORBaseViewController ,CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, UITableViewDataSource {
    var bluetoothManager : CBCentralManager?
    
    //MARK: - Class properties
    var connectedPeripheral                             : CBPeripheral?
    var bgmRecordAccessControlPointCharacteristic       : CBCharacteristic?
    var readings                                        : NSMutableArray?
    var dateFormatter                                   : DateFormatter
    var bgmServiceUUID                                  : CBUUID
    var bgmGlucoseMeasurementCharacteristicUUID         : CBUUID
    var bgmGlucoseMeasurementContextCharacteristicUUID  : CBUUID
    var bgmRecordAccessControlPointCharacteristicUUID   : CBUUID
    var batteryServiceUUID                              : CBUUID
    var batteryLevelCharacteristicUUID                  : CBUUID

    enum BGMViewActions : Int {
        case refresh            = 0
        case allRecords         = 1
        case firstRecord        = 2
        case lastRecord         = 3
        case clear              = 4
        case deleteAllRecords   = 5
        case cancel             = 6
    }
    
    //MARK: - ViewController outlets
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var bgmTableView: UITableView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var recordsButton: UIButton!
    @IBOutlet weak var verticalLabel: UILabel!

    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        handleAboutButtonTapped()
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        handleActionButtonTapped(from: sender)
    }
    
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        handleConnectionButtonTapped()
    }
    
    //MARK: - UIViewController Methods
    required init(coder aDecoder: NSCoder) {
        readings = NSMutableArray(capacity: 20)
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy, HH:mm"
        
        bgmServiceUUID                                  = CBUUID(string: NORServiceIdentifiers.bgmServiceUUIDString)
        bgmGlucoseMeasurementCharacteristicUUID         = CBUUID(string: NORServiceIdentifiers.bgmGlucoseMeasurementCharacteristicUUIDString)
        bgmGlucoseMeasurementContextCharacteristicUUID  = CBUUID(string: NORServiceIdentifiers.bgmGlucoseMeasurementContextCharacteristicUUIDString)
        bgmRecordAccessControlPointCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.bgmRecordAccessControlPointCharacteristicUUIDString)
        batteryServiceUUID                              = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID                  = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        verticalLabel.transform = CGAffineTransform(translationX: -(verticalLabel.frame.width/2) + (verticalLabel.frame.height / 2), y: 0.0).rotated(by: -.pi / 2)
        bgmTableView.dataSource = self
    }
    
    func handleActionButtonTapped(from view: UIView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Refresh", style: .default) { _ in
            if let reading = self.readings?.firstObject as? NORGlucoseReading {
                let data = Data(
                    [NORBGMOpCode.report_STORED_RECORDS.rawValue,
                    NORBGMOPerator.greater_THAN_OR_EQUAL.rawValue,
                    NORBGMFilterType.sequence_NUMBER.rawValue,
                    //Convert Endianess
                    UInt8(reading.sequenceNumber! & 0xFF),
                    UInt8(reading.sequenceNumber! >> 8)]
                )
                self.readings?.removeAllObjects()
                self.bgmTableView.reloadData()
                
                self.connectedPeripheral?.writeValue(data, for: self.bgmRecordAccessControlPointCharacteristic!, type: .withResponse)
            }
        })
        alert.addAction(UIAlertAction(title: "All", style: .default) { _ in
            let data = Data([NORBGMOpCode.report_STORED_RECORDS.rawValue, NORBGMOPerator.all_RECORDS.rawValue])
            self.connectedPeripheral?.writeValue(data, for: self.bgmRecordAccessControlPointCharacteristic!, type: .withResponse)
        })
        alert.addAction(UIAlertAction(title: "First", style: .default) { _ in
            let data = Data([NORBGMOpCode.report_STORED_RECORDS.rawValue, NORBGMOPerator.first_RECORD.rawValue])
            self.connectedPeripheral?.writeValue(data, for: self.bgmRecordAccessControlPointCharacteristic!, type: .withResponse)
        })
        alert.addAction(UIAlertAction(title: "Last", style: .default) { _ in
            let data = Data([NORBGMOpCode.report_STORED_RECORDS.rawValue, NORBGMOPerator.last_RECORD.rawValue])
            self.connectedPeripheral?.writeValue(data, for: self.bgmRecordAccessControlPointCharacteristic!, type: .withResponse)
        })
        alert.addAction(UIAlertAction(title: "Clear", style: .default) { _ in
            self.readings?.removeAllObjects()
            self.bgmTableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            let data = Data([NORBGMOpCode.delete_STORED_RECORDS.rawValue, NORBGMOPerator.all_RECORDS.rawValue])
            self.connectedPeripheral?.writeValue(data, for: self.bgmRecordAccessControlPointCharacteristic!, type: .withResponse)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }

    func handleAboutButtonTapped() {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .bgm))
    }
    
    func handleConnectionButtonTapped() {
        guard connectedPeripheral != nil else {
            return
        }

        bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
    }
    
    func clearUI() {
        readings?.removeAllObjects()
        DispatchQueue.main.async {
            self.bgmTableView.reloadData()
            self.deviceName.text = "DEFAULT_BGM"
            self.battery.tag = 0
            self.battery.setTitle("n/a", for: .disabled)
        }
    }
    
    func enableActionButton() {
        recordsButton.isEnabled = true
        recordsButton.backgroundColor = UIColor.black
        recordsButton.setTitleColor(UIColor.white, for: UIControl.State())
    }

    func disableActionButton() {
        recordsButton.isEnabled = false
        recordsButton.backgroundColor = UIColor.lightGray
        recordsButton.setTitleColor(UIColor.lightText, for: UIControl.State())
    }
    
    func setupNotifications() {
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
    }
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.applicationDidEnterBackgroundHandler),
                                                         name: UIApplication.didEnterBackgroundNotification,
                                                         object: nil)
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.applicationDidBecomeActiveHandler),
                                                         name: UIApplication.didBecomeActiveNotification,
                                                         object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self,
                                                            name: UIApplication.didBecomeActiveNotification,
                                                            object: nil)
        NotificationCenter.default.removeObserver(self,
                                                            name: UIApplication.didEnterBackgroundNotification,
                                                            object: nil)
    }
    
    @objc func applicationDidEnterBackgroundHandler() {
        let name = connectedPeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    @objc func applicationDidBecomeActiveHandler(){
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    //MARK: - CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService: CBService in peripheral.services! {
            if aService.uuid.isEqual(bgmServiceUUID) {
                peripheral.discoverCharacteristics(
                    [bgmGlucoseMeasurementCharacteristicUUID, bgmGlucoseMeasurementContextCharacteristicUUID, bgmRecordAccessControlPointCharacteristicUUID],
                    for: aService)
            } else if aService.uuid.isEqual(batteryServiceUUID){
                peripheral.discoverCharacteristics([batteryLevelCharacteristicUUID], for: aService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error occurred while discovering characteristic: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        if service.uuid.isEqual(bgmServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(bgmGlucoseMeasurementCharacteristicUUID){
                    peripheral.setNotifyValue(true, for: aCharacteristic)
                } else if aCharacteristic.uuid.isEqual(bgmGlucoseMeasurementContextCharacteristicUUID) {
                    peripheral.setNotifyValue(true, for: aCharacteristic)
                } else if aCharacteristic.uuid.isEqual(bgmRecordAccessControlPointCharacteristicUUID) {
                    bgmRecordAccessControlPointCharacteristic = aCharacteristic
                    peripheral.setNotifyValue(true, for: aCharacteristic)
                }
            }
        } else if service.uuid.isEqual(batteryServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(batteryLevelCharacteristicUUID){
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
        
        var array = UnsafeMutablePointer<UInt8>(OpaquePointer(((characteristic.value as NSData?)?.bytes)!))
        
        if characteristic.uuid.isEqual(batteryLevelCharacteristicUUID) {
            let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &array)
            let text = "\(batteryLevel)%"
            
            DispatchQueue.main.async(execute: {
                self.battery.setTitle(text, for: UIControl.State.disabled)
                if self.battery.tag == 0 {
                    // If battery level notifications are available, enable them
                    if characteristic.properties.contains(CBCharacteristicProperties.notify)
                    {
                        self.battery.tag = 1; // mark that we have enabled notifications
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            })
            
        } else if characteristic.uuid.isEqual(bgmGlucoseMeasurementCharacteristicUUID) {
            print("New glucose reading")
            let reading = NORGlucoseReading.readingFromBytes(UnsafeMutablePointer(array))
            
            if (readings?.contains(reading) != false) {
                readings?.replaceObject(at: (readings?.index(of: reading))!, with: reading)
            } else {
                readings?.add(reading)
            }
        } else if characteristic.uuid.isEqual(bgmGlucoseMeasurementContextCharacteristicUUID) {
            let context = NORGlucoseReadingContext.readingContextFromBytes(UnsafeMutablePointer(array))
            let index = readings?.index(of: context)
            if index != NSNotFound {
                let reading = readings?.object(at: index!) as! NORGlucoseReading
                reading.context = context
            } else {
                if let sn = context.sequenceNumber {
                    print("Glucose measurement with sequence number: \(sn) not found")
                } else {
                    print("Glucose measurement with unknown sequence number not found")
                }
            }
        } else if characteristic.uuid.isEqual(bgmRecordAccessControlPointCharacteristicUUID) {
            print("OpCode: \(array[0]), Operator: \(array[2])")
            DispatchQueue.main.async(execute: {
                switch(NORBGMResponseCode(rawValue:array[2])!){
                case .success:
                    self.bgmTableView.reloadData()
                    break
                case .op_CODE_NOT_SUPPORTED:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Operation not supported", from: self)
                case .no_RECORDS_FOUND:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "No records found", from: self)
                case .operator_NOT_SUPPORTED:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Operator not supported", from: self)
                case .invalid_OPERATOR:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Invalid operator", from: self)
                case .operand_NOT_SUPPORTED:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Operand not supported", from: self)
                case .invalid_OPERAND:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Invalid operand", from: self)
                case .abort_UNSUCCESSFUL:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Abort unsuccessful", from: self)
                case .procedure_NOT_COMPLETED:
                    NORAppUtilities.showAlert(title: "Error", andMessage: "Procedure not completed", from: self)
                case .reserved:
                    break
                }
            })
        }
    }
    //MARK: - CBCentralManagerDelegate Methdos
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Bluetooth powered off")
        } else {
            print("Bluetooth powered on")
        }
    }
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        connectedPeripheral = aPeripheral
        connectedPeripheral?.delegate = self
        bluetoothManager = aManager
        bluetoothManager?.delegate = self
        let options = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)
        bluetoothManager?.connect(aPeripheral, options: options as? [String : AnyObject])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.discoverServices([bgmServiceUUID, batteryServiceUUID])
        DispatchQueue.main.async {
            self.deviceName.text = peripheral.name
            self.connectButton.setTitle("DISCONNECT", for: UIControl.State())
            self.enableActionButton()
            self.setupNotifications()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Please Try again", from: self)
            self.connectButton.setTitle("CONNECT", for: UIControl.State())
            self.connectedPeripheral = nil
            self.disableActionButton()
            self.clearUI()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async { 
            self.connectButton.setTitle("CONNECT", for: UIControl.State())
            
            if NORAppUtilities.isApplicationInactive() == true {
                let name = peripheral.name ?? "Peripheral"
                NORAppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
            }
            self.disableActionButton()
            self.clearUI()
            self.removeNotificationObservers()
        }
    }
    
    //MARK: - UITableViewDataSoruce methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readings!.count
    }
    
    //MARK: - UITableViewDelegate methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BGMCell") as! NORBGMItemCell
        
        let reading = (readings?.object(at: (indexPath as NSIndexPath).row))! as! NORGlucoseReading
        cell.timestamp.text = dateFormatter.string(from: reading.timestamp! as Date)
        
        if reading.glucoseConcentrationTypeAndLocationPresent == true {
            cell.type.text = reading.typeAsString()

            switch reading.unit! {
            case .mol_L:
                cell.value.text = String(format: "%.1f", reading.glucoseConcentration! * 1000)   // mol/l -> mmol/l conversion
                cell.unit.text = "mmol/l"
                break
            case .kg_L:
                cell.value.text = String(format: "%0f", reading.glucoseConcentration! * 100000)  // kg/l -> mg/dl conversion
                cell.unit.text = "mg/dl"
                break
            }
        } else {
            cell.value.text = "-"
            cell.type.text = "Unavailable"
            cell.unit.text = ""
        }
        
        return cell
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.children.first as! NORScannerViewController
            controller.filterUUID = bgmServiceUUID
            controller.delegate = self
        } else if segue.identifier == "details" {
            let controller = segue.destination as! NORBGMDetailsViewController
            controller.reading = readings?.object(at: ((bgmTableView.indexPathForSelectedRow as NSIndexPath?)?.row)!) as? NORGlucoseReading
        }
    }
}
