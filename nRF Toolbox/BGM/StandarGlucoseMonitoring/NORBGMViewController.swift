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


class NORBGMViewController: NORBaseViewController ,CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, UITableViewDataSource, UIActionSheetDelegate {
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
    
    @IBAction func actionButtonTapped(_ sender: AnyObject) {
        handleActionButtonTapped()
    }
    
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        handleConnectionButtonTapped()
    }
    
    //MARK: - UIViewController Methods
    required init(coder aDecoder: NSCoder) {
        readings = NSMutableArray(capacity: 20)
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy, hh:mm"
        
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
        verticalLabel.transform = CGAffineTransform(translationX: -145.0, y: 0.0).rotated(by: (CGFloat)(-M_PI_2))
        bgmTableView.dataSource = self
    }
    
    func handleActionButtonTapped() {
        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        actionSheet.addButton(withTitle: "Refresh")
        actionSheet.addButton(withTitle: "All")
        actionSheet.addButton(withTitle: "First")
        actionSheet.addButton(withTitle: "Last")
        actionSheet.addButton(withTitle: "Clear")
        actionSheet.addButton(withTitle: "Delete All")
        actionSheet.addButton(withTitle: "Cancel")
        actionSheet.destructiveButtonIndex = BGMViewActions.deleteAllRecords.rawValue
        actionSheet.cancelButtonIndex      = BGMViewActions.cancel.rawValue
        
        actionSheet.show(in: self.view)
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
        bgmTableView.reloadData()
        deviceName.text = "DEFAULT_BGM"
        battery.tag = 0
        battery.setTitle("n/a", for: UIControlState.disabled)
    }
    
    func enableActionButton() {
        recordsButton.isEnabled = true
        recordsButton.backgroundColor = UIColor.black
        recordsButton.setTitleColor(UIColor.white, for: UIControlState())
    }

    func disableActionButton() {
        recordsButton.isEnabled = false
        recordsButton.backgroundColor = UIColor.lightGray
        recordsButton.setTitleColor(UIColor.lightText, for: UIControlState())
    }
    
    func setupNotifications() {
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
    }
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.applicationDidEnterBackgroundHandler),
                                                         name: NSNotification.Name.UIApplicationDidEnterBackground,
                                                         object: nil)
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.applicationDidBecomeActiveHandler),
                                                         name: NSNotification.Name.UIApplicationDidBecomeActive,
                                                         object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self,
                                                            name: NSNotification.Name.UIApplicationDidBecomeActive,
                                                            object: nil)
        NotificationCenter.default.removeObserver(self,
                                                            name: NSNotification.Name.UIApplicationDidEnterBackground,
                                                            object: nil)
    }
    
    func applicationDidEnterBackgroundHandler() {
        let name = connectedPeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    func applicationDidBecomeActiveHandler(){
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
                self.battery.setTitle(text, for: UIControlState.disabled)
            })
            if battery.tag == 0 {
                // If battery level notifications are available, enable them
                if characteristic.properties.contains(CBCharacteristicProperties.notify)
                {
                    battery.tag = 1; // mark that we have enabled notifications
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
            
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
                print("Glucose measurement with sequence number: \(context.sequenceNumber) not found")
            }
        } else if characteristic.uuid.isEqual(bgmRecordAccessControlPointCharacteristicUUID) {
            print("OpCode: \(array[0]), Operator: \(array[2])")
            DispatchQueue.main.async(execute: {
                switch(NORBGMResponseCode(rawValue:array[2])!){
                case .success:
                    self.bgmTableView.reloadData()
                    break
                case .op_CODE_NOT_SUPPORTED:
                    let alert = UIAlertView.init(title: "Error", message: "Operation not supported", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .no_RECORDS_FOUND:
                    let alert = UIAlertView.init(title: "Error", message: "No records found", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .operator_NOT_SUPPORTED:
                    let alert = UIAlertView.init(title: "Error", message: "Operator not supported", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .invalid_OPERATOR:
                    let alert = UIAlertView.init(title: "Error", message: "Invalid operator", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .operand_NOT_SUPPORTED:
                    let alert = UIAlertView.init(title: "Error", message: "Operand not supported", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .invalid_OPERAND:
                    let alert = UIAlertView.init(title: "Error", message: "Invalid operand", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .abort_UNSUCCESSFUL:
                    let alert = UIAlertView.init(title: "Error", message: "Abort unsuccessful", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case .procedure_NOT_COMPLETED:
                    let alert = UIAlertView.init(title: "Error", message: "Procedure not completed", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
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
        bluetoothManager = aManager
        bluetoothManager?.delegate = self
        
        aPeripheral.delegate = self
        let options = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)
        bluetoothManager?.connect(aPeripheral, options: options as? [String : AnyObject])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.deviceName.text = peripheral.name
            self.connectButton.setTitle("DISCONNECT", for: UIControlState())
            self.enableActionButton()
            self.setupNotifications()
        }
        connectedPeripheral = peripheral
        peripheral.discoverServices([bgmServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Please Try again")
            self.connectButton.setTitle("CONNECT", for: UIControlState())
            self.connectedPeripheral = nil
            self.disableActionButton()
            self.clearUI()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async { 
            self.connectButton.setTitle("CONNECT", for: UIControlState())
            
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
    
    //MARK: - UIActionSheetDelegate Methods
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        guard buttonIndex != BGMViewActions.cancel.rawValue else {
            return
        }

        var accessParam : [UInt8] = []
        var clearList : Bool = true
        
        switch  BGMViewActions(rawValue: buttonIndex)! {
        case .refresh:
            if readings?.count > 0 {
                let reading = readings?.object(at: 0) as! NORGlucoseReading
                accessParam.append(NORBGMOpCode.report_STORED_RECORDS.rawValue)
                accessParam.append(NORBGMOPerator.greater_THAN_OR_EQUAL.rawValue)
                accessParam.append(NORBGMFilterType.sequence_NUMBER.rawValue)
                //Convert Endianess
                accessParam.append(UInt8(reading.sequenceNumber! & 0xFF))
                accessParam.append(UInt8(reading.sequenceNumber! >> 8))
                clearList = true
            }
            break
        case .allRecords:
            accessParam.append(NORBGMOpCode.report_STORED_RECORDS.rawValue)
            accessParam.append(NORBGMOPerator.all_RECORDS.rawValue)
            break
        case .firstRecord:
            accessParam.append(NORBGMOpCode.report_STORED_RECORDS.rawValue)
            accessParam.append(NORBGMOPerator.first_RECORD.rawValue)
            break
        case .lastRecord:
            accessParam.append(NORBGMOpCode.report_STORED_RECORDS.rawValue)
            accessParam.append(NORBGMOPerator.last_RECORD.rawValue)
            break
        case .clear:
            //NOOP
            break
        case .deleteAllRecords:
            accessParam.append(NORBGMOpCode.delete_STORED_RECORDS.rawValue)
            accessParam.append(NORBGMOPerator.all_RECORDS.rawValue)
            break
        default:
            break
        }
        
        if clearList == true {
            readings?.removeAllObjects()
            bgmTableView.reloadData()
        }
        
        if accessParam.count > 0 {
            let data = Data(bytes: UnsafePointer<UInt8>(accessParam), count: accessParam.count)
            connectedPeripheral?.writeValue(data, for: bgmRecordAccessControlPointCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.childViewControllerForStatusBarHidden as! NORScannerViewController
            controller.filterUUID = bgmServiceUUID
            controller.delegate = self
        } else if segue.identifier == "details" {
            let controller = segue.destination as! NORBGMDetailsViewController
            controller.reading = readings?.object(at: ((bgmTableView.indexPathForSelectedRow as NSIndexPath?)?.row)!) as? NORGlucoseReading
        }
    }
}
