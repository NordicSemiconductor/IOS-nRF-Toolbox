//
//  NORBGMViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 29/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORBGMViewController: NORBaseViewController ,CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, UITableViewDataSource, UIActionSheetDelegate {
    var bluetoothManager : CBCentralManager?
    
    //MARK: - Class properties
    var connectedPeripheral                             : CBPeripheral?
    var bgmRecordAccessControlPointCharacteristic       : CBCharacteristic?
    var readings                                        : NSMutableArray?
    var dateFormatter                                   : NSDateFormatter?
    var bgmServiceUUID                                  : CBUUID?
    var bgmGlucoseMeasurementCharacteristicUUID         : CBUUID?
    var bgmGlucoseMeasurementContextCharacteristicUUID  : CBUUID?
    var bgmRecordAccessControlPointCharacteristicUUID   : CBUUID?
    var batteryServiceUUID                              : CBUUID?
    var batteryLevelCharacteristicUUID                  : CBUUID?

    enum BGMViewActions : Int {
        case Refresh            = 0
        case AllRecords         = 1
        case FirstRecord        = 2
        case LastRecord         = 3
        case Clear              = 4
        case DeleteAllRecords   = 5
        case Cancel             = 6
    }
    
    //MARK: - ViewController outlets
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var bgmTableView: UITableView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var recordsButton: UIButton!
    @IBOutlet weak var verticalLabel: UILabel!

    @IBAction func aboutButtonTapped(sender: AnyObject) {
        handleAboutButtonTapped()
    }
    
    @IBAction func actionButtonTapped(sender: AnyObject) {
        handleActionButtonTapped()
    }
    
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        handleConnectionButtonTapped()
    }
    
    //MARK: - UIViewController Methods
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        readings = NSMutableArray(capacity: 20)
        dateFormatter = NSDateFormatter()
        dateFormatter?.dateFormat = "dd.MM.yyyy, hh:mm"
        
        bgmServiceUUID                                  = CBUUID(string: NORServiceIdentifiers.bgmServiceUUIDString)
        bgmGlucoseMeasurementCharacteristicUUID         = CBUUID(string: NORServiceIdentifiers.bgmGlucoseMeasurementCharacteristicUUIDString)
        bgmGlucoseMeasurementCharacteristicUUID         = CBUUID(string: NORServiceIdentifiers.bgmGlucoseMeasurementCharacteristicUUIDString)
        bgmRecordAccessControlPointCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.bgmRecordAccessControlPointCharacteristicUUIDString)
        batteryServiceUUID                              = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID                  = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-145.0, 0.0), (CGFloat)(-M_PI_2))
        bgmTableView.dataSource = self
    }
    
    func handleActionButtonTapped() {
        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        actionSheet.addButtonWithTitle("Refresh")
        actionSheet.addButtonWithTitle("All")
        actionSheet.addButtonWithTitle("First")
        actionSheet.addButtonWithTitle("Last")
        actionSheet.addButtonWithTitle("Clear")
        actionSheet.addButtonWithTitle("Delete All")
        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.destructiveButtonIndex = BGMViewActions.DeleteAllRecords.rawValue
        actionSheet.cancelButtonIndex      = BGMViewActions.Cancel.rawValue
        
        actionSheet.showInView(self.view)
    }

    func handleAboutButtonTapped() {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .BGM))
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
        battery.setTitle("n/a", forState: UIControlState.Disabled)
    }
    
    func enableActionButton() {
        recordsButton.enabled = true
        recordsButton.backgroundColor = UIColor.blackColor()
        recordsButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }

    func disableActionButton() {
        recordsButton.enabled = false
        recordsButton.backgroundColor = UIColor.lightGrayColor()
        recordsButton.setTitleColor(UIColor.lightTextColor(), forState: UIControlState.Normal)
    }
    
    func setupNotifications() {
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
        }
    }
    
    func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.applicationDidEnterBackgroundHandler),
                                                         name: UIApplicationDidEnterBackgroundNotification,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.applicationDidBecomeActiveHandler),
                                                         name: UIApplicationDidBecomeActiveNotification,
                                                         object: nil)
    }
    
    func removeNotificationObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: UIApplicationDidBecomeActiveNotification,
                                                            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
                                                            name: UIApplicationDidEnterBackgroundNotification,
                                                            object: nil)
    }
    
    func applicationDidEnterBackgroundHandler() {
        NORAppUtilities.showBackgroundNotification(message: String(format: "You are still connected to %s peripheral. It will collect data also in background.", (connectedPeripheral?.name)!))
    }
    
    func applicationDidBecomeActiveHandler(){
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    //MARK: - CBPeripheralDelegate Methods
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print(String(format: "Error discovering service: %s", (error?.localizedDescription)!))
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
            return
        }
        
        for aService: CBService in peripheral.services! {
            if aService.UUID.isEqual(bgmServiceUUID) {
                connectedPeripheral?.discoverCharacteristics([bgmGlucoseMeasurementCharacteristicUUID!,bgmGlucoseMeasurementContextCharacteristicUUID!, bgmRecordAccessControlPointCharacteristicUUID!],
                    forService: aService)
            }else if aService.UUID.isEqual(batteryServiceUUID){
                connectedPeripheral?.discoverCharacteristics([batteryLevelCharacteristicUUID!], forService: aService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if service.UUID.isEqual(bgmServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID.isEqual(bgmGlucoseMeasurementCharacteristicUUID){
                    peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
                }else if aCharacteristic.UUID.isEqual(bgmGlucoseMeasurementContextCharacteristicUUID){
                    peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
                }else if aCharacteristic.UUID.isEqual(bgmRecordAccessControlPointCharacteristicUUID) {
                    bgmRecordAccessControlPointCharacteristic = aCharacteristic
                    peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
                }
            }
        }else if service.UUID.isEqual(batteryServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID.isEqual(batteryLevelCharacteristicUUID){
                    peripheral.readValueForCharacteristic(aCharacteristic)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let data  = characteristic.value
        let array = data!.bytes
        
        if characteristic.UUID.isEqual(batteryLevelCharacteristicUUID) {
            let batteryLevel = CharacteristicReader.readUInt8Value(UnsafeMutablePointer(array))
            let text = String(format: "%d%%", batteryLevel)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.battery.setTitle(text, forState: UIControlState.Disabled)
            })
            if battery.tag == 0 {
                // If battery level notifications are available, enable them
                if characteristic.properties.contains(CBCharacteristicProperties.Notify)
                {
                    battery.tag = 1; // mark that we have enabled notifications
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
            
        } else if characteristic.UUID.isEqual(bgmGlucoseMeasurementCharacteristicUUID) {
            let reading = NORGlucoseReading.readingFromBytes(UnsafeMutablePointer(array))
            
            if (readings?.containsObject(reading) != false) {
                readings?.replaceObjectAtIndex((readings?.indexOfObject(reading))!, withObject: reading)
            } else {
                readings?.addObject(reading)
            }
        } else if characteristic.UUID.isEqual(bgmGlucoseMeasurementContextCharacteristicUUID) {
            let context = NORGlucoseReadingContext.readingContextFromBytes(UnsafeMutablePointer(array))
            let index = readings?.indexOfObject(context)
            if index != NSNotFound {
                let reading = readings?.objectAtIndex(index!) as! NORGlucoseReading
                reading.context = context
            }else{
                print("Glucose measurement with sequence number: %d not found", context.sequenceNumber)
            }
        } else if characteristic.UUID.isEqual(bgmRecordAccessControlPointCharacteristicUUID) {
            let param = unsafeBitCast(CFArrayGetValueAtIndex(array as! CFArray, 0), RecordAccessParam.self)
            dispatch_async(dispatch_get_main_queue(), {
                switch(param.value.response.responseCode){
                case SUCCESS.rawValue:
                    self.bgmTableView.reloadData()
                    break
                case OP_CODE_NOT_SUPPORTED.rawValue:
                    let alert = UIAlertView.init(title: "Error", message: "Operation not supported", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case NO_RECORDS_FOUND.rawValue:
                    let alert = UIAlertView.init(title: "Error", message: "No records found", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case OPERATOR_NOT_SUPPORTED.rawValue:
                    let alert = UIAlertView.init(title: "Error", message: "Operator not supported", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case INVALID_OPERATOR.rawValue:
                    let alert = UIAlertView.init(title: "Error", message: "Invalid operator", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case OPERAND_NOT_SUPPORTED.rawValue:
                    let alert = UIAlertView.init(title: "Error", message: "Operand not supported", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                case INVALID_OPERAND.rawValue:
                    let alert = UIAlertView.init(title: "Error", message: "Invalid operand", delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    break
                    default:
                        print(String(format:"Op code: %d, operator %d", param.opCode, param.operatorType))
                        print(String(format:"Req Op Code: %d, response: %d", param.value.response.requestOpCode, param.value.response.responseCode))
                    break
                }
            })
        }
    }
    //MARK: - CBCentralManagerDelegate Methdos
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state != CBCentralManagerState.PoweredOn {
            print("Bluetooth is not on!")
        }
    }
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        bluetoothManager = aManager
        bluetoothManager?.delegate = self
        
        aPeripheral.delegate = self
        let options = NSDictionary(object: NSNumber(bool: true), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey)
        bluetoothManager?.connectPeripheral(aPeripheral, options: options as? [String : AnyObject])
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        dispatch_async(dispatch_get_main_queue()) {
            self.deviceName.text = peripheral.name
            self.connectButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
            self.enableActionButton()
            self.setupNotifications()
        }
        connectedPeripheral = peripheral
        connectedPeripheral?.discoverServices([bgmServiceUUID!, batteryServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Please Try again")
            self.connectButton.setTitle("CONNECT", forState: UIControlState.Normal)
            self.connectedPeripheral = nil
            self.disableActionButton()
            self.clearUI()
        }
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) { 
            self.connectButton.setTitle("CONNECT", forState: UIControlState.Normal)
            
            if NORAppUtilities.isApplicationInactive() == true {
                NORAppUtilities.showBackgroundNotification(message: String(format: "%s peripheral is disconnected", peripheral.name!))
            }
            self.disableActionButton()
            self.clearUI()
            self.removeNotificationObservers()
        }
    }
    
    //MARK: - UITableViewDataSoruce methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readings!.count
    }
    
    //MARK: - UITableViewDelegate methods
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BGMCell") as! NORBGMItemCell
        
        let reading = (readings?.objectAtIndex(indexPath.row))! as! NORGlucoseReading
        cell.timestamp.text = dateFormatter?.stringFromDate(reading.timestamp!)
        
        if reading.glucoseConcentrationTypeAndLocationPresent == true {
            cell.type.text = reading.typeAsString()

            switch reading.unit! {
            case .MOL_L:
                cell.value.text = String(format: "%.1f", reading.glucoseConcentration! * 1000)   // mol/l -> mmol/l conversion
                cell.unit.text = "mmol/l"
                break
            case .KG_L:
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
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        guard buttonIndex != BGMViewActions.Cancel.rawValue else {
            return
        }
        
        var param : RecordAccessParam?
        var size  : Int = 0
        var clearList : Bool = true
        
        switch buttonIndex {
        case BGMViewActions.Refresh.rawValue:
            if readings?.count > 0 {
                param?.opCode = UInt8(REPORT_STORED_RECORDS.rawValue)
                param?.operatorType = UInt8(GREATER_THAN_OR_EQUAL.rawValue)
                param?.value.singleParam.filterType = UInt8(SEQUENCE_NUMBER.rawValue)
                let reading = readings?.objectAtIndex((readings?.count)! - 1) as! NORGlucoseReading
                param?.value.singleParam.paramLE = CFSwapInt16HostToLittle(reading.sequenceNumber!)
                size = 5
                clearList = false
                
                break
            }else{
                //Fall through
            }
        case BGMViewActions.AllRecords.rawValue:
            param?.opCode = UInt8(REPORT_STORED_RECORDS.rawValue)
            param?.operatorType = UInt8(ALL_RECORDS.rawValue)
            size = 2
            break
        case BGMViewActions.FirstRecord.rawValue:
            param?.opCode = UInt8(REPORT_STORED_RECORDS.rawValue)
            param?.operatorType = UInt8(FIRST_RECORD.rawValue)
            size = 2
            break
        case BGMViewActions.LastRecord.rawValue:
            param?.opCode = UInt8(REPORT_STORED_RECORDS.rawValue)
            param?.operatorType = UInt8(LAST_RECORD.rawValue)
            size = 2
            break
        case BGMViewActions.Clear.rawValue:
            //NOOP
            break
        case BGMViewActions.DeleteAllRecords.rawValue:
            param?.opCode = UInt8(DELETE_STORED_RECORDS.rawValue)
            param?.operatorType = UInt8(ALL_RECORDS.rawValue)
            size = 2
            break
        default:
            break
        }
        
        if clearList == true {
            readings?.removeAllObjects()
            bgmTableView.reloadData()
        }
        
        if size > 0 {
            let data = NSData(bytes: &param, length: size)
            connectedPeripheral?.writeValue(data, forCharacteristic: bgmRecordAccessControlPointCharacteristic!, type: CBCharacteristicWriteType.WithResponse)
        }
    }
    
    //MARK: - Segue methods
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return identifier != "scan" || connectedPeripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.childViewControllerForStatusBarHidden() as! NORScannerViewController
            controller.filterUUID = bgmServiceUUID
            controller.delegate = self
        }else if segue.identifier == "details" {
            let controller = segue.destinationViewController as! NORBGMDetailsViewController
            controller.reading = readings?.objectAtIndex((bgmTableView.indexPathForSelectedRow?.row)!) as? NORGlucoseReading
        }
    }
}
