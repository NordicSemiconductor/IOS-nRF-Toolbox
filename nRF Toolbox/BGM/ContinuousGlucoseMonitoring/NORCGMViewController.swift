/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import CoreBluetooth


enum viewActionTypes : Int {
    case ACTION_START_SESSION = 0
    case ACTION_STOP_SESSION  = 1
    case ACTION_SET_TIME      = 2
}

class NORCGMViewController : NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, UITableViewDataSource, UIActionSheetDelegate {

    //MARK: - Class porperties
    var bluetoothManager : CBCentralManager?

    var dateFormat : NSDateFormatter

    var cbgmServiceUUID : CBUUID
    var cgmGlucoseMeasurementCharacteristicUUID : CBUUID
    var cgmGlucoseMeasurementContextCharacteristicUUID : CBUUID
    var cgmRecordAccessControlPointCharacteristicUUID : CBUUID
    var cgmFeatureCharacteristicUUID : CBUUID
    var cgmStatusCharacteristicUUID : CBUUID
    var cgmSessionStartTimeCharacteristicUUID : CBUUID
    var cgmSessionRunTimeCharacteristicUUID : CBUUID
    var cgmSpecificOpsControlPointCharacteristicUUID : CBUUID
    var batteryServiceUUID : CBUUID
    var batteryLevelCharacteristicUUID : CBUUID

    /*!
     * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
     * after user press Disconnect button.
     */
    var connectedPeripheral : CBPeripheral?
    var cgmRecordAccessControlPointCharacteristic : CBCharacteristic?
    var cgmFeatureCharacteristic : CBCharacteristic?
    var cgmSpecificOpsControlPointCharacteristic : CBCharacteristic?
    var readings : NSMutableArray?
    var cgmFeatureData : NORCGMFeatureData?

    //MARK: View Outlets / Actions
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var deviceName : UILabel!
    @IBOutlet weak var connectionButton : UIButton!
    @IBOutlet weak var recordButton : UIButton!
    @IBOutlet weak var cbgmTableView : UITableView!
    @IBOutlet weak var cgmActivityIndicator : UIActivityIndicatorView!
    
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        self.handleConnectionButtonTapped()
    }
    @IBAction func actionButtonTapped(sender: AnyObject) {
        self.handleActionButtonTapped()
    }
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.handleAboutButtonTapped()
    }

    //MARK: - UIViewController methods
    // Custom initialization
    required init?(coder aDecoder: NSCoder) {
        readings = NSMutableArray(capacity: 20)
        dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "dd.MM.yyyy, hh:mm"
        cbgmServiceUUID = CBUUID(string: NORServiceIdentifiers.cgmServiceUUIDString)
        cgmGlucoseMeasurementCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cgmGlucoseMeasurementCharacteristicUUIDString)
        cgmGlucoseMeasurementContextCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.bgmGlucoseMeasurementContextCharacteristicUUIDString)
        cgmRecordAccessControlPointCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.bgmRecordAccessControlPointCharacteristicUUIDString)
        cgmFeatureCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cgmFeatureCharacteristicUUIDString)
        cgmStatusCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cgmStatusCharacteristicUUIDString)
        cgmSessionStartTimeCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cgmSessionStartTimeCharacteristicUUIDString)
        cgmSessionRunTimeCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cgmSessionRunTimeCharacteristicUUIDString)
        cgmSpecificOpsControlPointCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.cgmSpecificOpsControlPointCharacteristicUUIDString)
        batteryServiceUUID = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Rotate the vertical label
        self.verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-145.0, 0.0), CGFloat(-M_PI_2))
        cbgmTableView.dataSource = self
    }
    
    func appdidEnterBackground() {
        NORAppUtilities.showBackgroundNotification(message: String(format: "You are still connected to %@ peripheral. It will collect data also in background.", connectedPeripheral!.name!))
    }
    
    func appDidBecomeActiveBackground(aNotification : NSNotification) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func handleActionButtonTapped() {
        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        actionSheet.addButtonWithTitle("Start Session")
        actionSheet.addButtonWithTitle("Stop Session")
        actionSheet.addButtonWithTitle("Set Update Interval")
        actionSheet.destructiveButtonIndex = 1
        
        actionSheet.showInView(self.view)
    }
    
    func handleAboutButtonTapped() {
        self.showAbout(message: NORAppUtilities.cgmHelpText)
    }
    
    func handleConnectionButtonTapped() {
        if connectedPeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(connectedPeripheral!)
        }
    }

    func parseCGMFeatureCharacteristic() {
        guard cgmFeatureCharacteristic?.value != nil else{
            return
        }

        let data       = cgmFeatureCharacteristic!.value
        let arrayBytes = UnsafeMutablePointer<UInt8>((data?.bytes)!)
        cgmFeatureData = NORCGMFeatureData(withBytes: arrayBytes)
    }

    func enableRecordButton() {
        recordButton.enabled = true
        recordButton.backgroundColor = UIColor.blackColor()
        recordButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }
    
    func disableRecordButton() {
        recordButton.enabled = false
        recordButton.backgroundColor = UIColor.lightGrayColor()
        recordButton.setTitleColor(UIColor.lightTextColor(), forState: .Normal)
    }

    func clearUI() {
        readings?.removeAllObjects()
        cbgmTableView.reloadData()
        deviceName.text = "DEFAULT CGM"
        
        battery.tag = 0
        battery.setTitle("n/a", forState:.Normal)
    }
    
    func showErrorAlert(withMessage aMessage : String) {
        dispatch_async(dispatch_get_main_queue(), {
            let alertView = UIAlertView(title: "Error", message: aMessage, delegate: nil, cancelButtonTitle: "Ok")
            alertView.show()
        })
    }
    
    //MARK: - Scanner Delegate methods
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager
        bluetoothManager?.delegate = self
        
        // The sensor has been selected, connect to it
        aPeripheral.delegate = self
        let connectionOptions = NSDictionary(object: NSNumber(bool: true), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey)

        bluetoothManager?.connectPeripheral(aPeripheral, options: connectionOptions as? [String : AnyObject])
    }

    //MARK: - Table View Datasource delegate methods

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (readings?.count)!
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aReading = readings?.objectAtIndex(indexPath.row) as? NORCGMReading
        let aCell = tableView.dequeueReusableCellWithIdentifier("CGMCell", forIndexPath: indexPath) as? NORCGMItemCell

        aCell?.type.text = aReading?.typeAsString()
        aCell?.timestamp.text = dateFormat.stringFromDate(NSDate.init(timeIntervalSinceNow: Double((aReading?.timeOffsetSinceSessionStart)!)))
        aCell?.value.text = String(format: "%.0f", (aReading?.glucoseConcentration)!)
        aCell?.unit.text = "mg/DL"
        
        return aCell!
    }

    func showUserInputAlert(withMessage aMessage: String) {
        dispatch_async(dispatch_get_main_queue(), {
            let alert = UIAlertView(title: "Input", message: aMessage, delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Set")
            alert.alertViewStyle = .PlainTextInput
            alert.textFieldAtIndex(0)!.keyboardType = .NumberPad
            alert.show()
        })
    }
    
    //MARK: - Segue navigation
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier == "scan" && connectedPeripheral == nil
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "scan" || segue.identifier == "details" else {
            return
        }
        
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc = segue.destinationViewController
            let controller = nc.childViewControllerForStatusBarHidden() as? NORScannerViewController

            controller?.filterUUID = cbgmServiceUUID
            controller?.delegate = self
        }
        
        if segue.identifier == "details" {
            let controller = segue.destinationViewController as? NORCGMDetailsViewController
            let aReading = readings!.objectAtIndex((cbgmTableView.indexPathForSelectedRow?.row)!)
            controller?.reading = aReading as? NORCGMReading
        }
    }

    //MARK: - Action Sheet delegate methods
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {

        var accessParam : [UInt8] = []
        var size  : NSInteger = 0
        var clearList :Bool = true
        var targetCharacteristic : CBCharacteristic?
        
        switch viewActionTypes(rawValue:buttonIndex)! {
        case .ACTION_START_SESSION:
            accessParam.append(NORCGMOpCode.START_SESSION.rawValue)
            size = 1
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic
            cgmActivityIndicator.startAnimating()
            clearList = false
            break
        case .ACTION_STOP_SESSION:
            accessParam.append(NORCGMOpCode.STOP_SESSION.rawValue)
            size = 1
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic
            cgmActivityIndicator.stopAnimating()
            clearList = false
            break
        case .ACTION_SET_TIME:
            self.showUserInputAlert(withMessage: "Enter update interval in minutes")
            clearList = false
            break
        }
        
        if clearList {
            readings!.removeAllObjects()
            cbgmTableView.reloadData()
        }
        
        if size > 0 {
            let data = NSData(bytes: &accessParam, length: size)
            print("Writing data: \(data) to \(targetCharacteristic!)")
            connectedPeripheral?.writeValue(data, forCharacteristic: targetCharacteristic!, type:.WithResponse)
        }
    }

    //MARK: - UIAlertViewDelegate / Helpers
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != 0 {
            var accessParam : [UInt8] = []
            let timeValue = Int(alertView.textFieldAtIndex(0)!.text!)
            accessParam.append(NORCGMOpCode.SET_COMMUNICATION_INTERVAL.rawValue)
            accessParam.append(UInt8(timeValue!))
            let data = NSData(bytes: &accessParam, length: 2)
            print("Writing data : \(data) to characteristic: \(cgmSpecificOpsControlPointCharacteristic)")
            connectedPeripheral?.writeValue(data, forCharacteristic: cgmSpecificOpsControlPointCharacteristic!, type: .WithResponse)
        }
    }
    //MARK: - Central Manager delegate methods
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state != .PoweredOn {
            print("Central manager not powered on!")
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", forState: .Normal)
            self.enableRecordButton()
            //Following if condition display user permission alert for background notification
            if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
                UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
            }

            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.appdidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.appDidBecomeActiveBackground), name: UIApplicationDidBecomeActiveNotification, object: nil)
        });
        
        // Peripheral has connected. Discover required services
        connectedPeripheral = peripheral
        connectedPeripheral?.discoverServices([cbgmServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to the peripheral failed. Try again")
            self.connectionButton.setTitle("CONNCET", forState: .Normal)
            self.connectedPeripheral = nil
            self.disableRecordButton()
            self.clearUI()
        });
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.connectionButton.setTitle("CONNECT", forState: .Normal)
            if NORAppUtilities.isApplicationInactive() {
                NORAppUtilities.showBackgroundNotification(message: String(format: "Peripheral %s is disconnected", peripheral.name!))
            }
            
            self.connectedPeripheral = nil
            
            self.disableRecordButton()
            self.clearUI()
            NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidEnterBackgroundNotification, object: nil)
        })
    }
    
    //MARK: - CBPeripheralDelegate methods
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print("Error discovering service: %@", error!.localizedDescription)
            self.bluetoothManager?.cancelPeripheralConnection(self.connectedPeripheral!)
            return
        }
        for aService in peripheral.services! {
            // Discovers the characteristics for a given service
            if  aService.UUID == cbgmServiceUUID {
                connectedPeripheral?.discoverCharacteristics(
                    [
                        cgmGlucoseMeasurementCharacteristicUUID,
                        cgmGlucoseMeasurementContextCharacteristicUUID,
                        cgmRecordAccessControlPointCharacteristicUUID,
                        cgmFeatureCharacteristicUUID,
                        cgmStatusCharacteristicUUID,
                        cgmSessionStartTimeCharacteristicUUID,
                        cgmSessionRunTimeCharacteristicUUID,
                        cgmSpecificOpsControlPointCharacteristicUUID
                    ], forService: aService)
            }
            else if aService.UUID == batteryServiceUUID {
                connectedPeripheral?.discoverCharacteristics([batteryLevelCharacteristicUUID], forService: aService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // Characteristics for one of those services has been found
        if service.UUID == cbgmServiceUUID {
            for characteristic in service.characteristics! {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)

                if characteristic.UUID == cgmFeatureCharacteristicUUID {
                    cgmFeatureCharacteristic = characteristic
                    peripheral.readValueForCharacteristic(cgmFeatureCharacteristic!)
                }
                if characteristic.UUID == cgmRecordAccessControlPointCharacteristicUUID {
                    cgmRecordAccessControlPointCharacteristic = characteristic
                }
                if characteristic.UUID == cgmSpecificOpsControlPointCharacteristicUUID {
                    cgmSpecificOpsControlPointCharacteristic = characteristic
                }
            }
        }else if service.UUID == batteryServiceUUID {
            for characteristic in service.characteristics! {
                if characteristic.UUID == batteryLevelCharacteristicUUID {
                    connectedPeripheral?.readValueForCharacteristic(characteristic)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // Decode the characteristic data
        let data = characteristic.value
        var array = UnsafeMutablePointer<UInt8>(data!.bytes)
        if characteristic.UUID == batteryLevelCharacteristicUUID {
            let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &array)
            let text = String(format:"%d%%", batteryLevel)
            
            // Scanner uses other queue to send events. We must edit UI in the main queue
            dispatch_async(dispatch_get_main_queue(), {
                self.battery.setTitle(text, forState: .Disabled)
            })
            
            if battery.tag == 0 {
                // If battery level notifications are available, enable them
                if characteristic.properties.contains(CBCharacteristicProperties.Notify) {
                    self.battery.tag = 1 // mark that we have enabled notifications
                    // Enable notification on data characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
        if characteristic.UUID == cgmGlucoseMeasurementCharacteristicUUID {
            dispatch_async(dispatch_get_main_queue(), {
                let reading = NORCGMReading(withBytes: array)
                if self.cgmFeatureData != nil {
                    reading.cgmFeatureData = self.cgmFeatureData
                }
                if self.readings!.containsObject(reading) {
                    // If the reading has been found (the same reading has the same sequence number), replace it with the new one
                    // The indexIfObjext method uses isEqual method from GlucodeReading (comparing by sequence number only)
                    self.readings!.replaceObjectAtIndex(self.readings!.indexOfObject(reading), withObject: reading)
                } else {
                    // If not, just add the new one to the array
                    self.readings!.addObject(reading)
                }
                self.cbgmTableView.reloadData()
            })
        }
        if characteristic.UUID == cgmSpecificOpsControlPointCharacteristicUUID {
            let responseCode = array[2]
            switch NORCGMOpcodeResponseCodes(rawValue: responseCode)! {
            case .OP_CODE_NOT_SUPPORTED:
                self.showErrorAlert(withMessage:"Operation not supported")
                break;
            case .SUCCESS:
                print("Success")
                break;
            case .INVALID_OPERAND:
                self.showErrorAlert(withMessage:"Invalid Operand")
                break
            case .PROCEDURE_NOT_COMPLETED:
                self.showErrorAlert(withMessage:"Procedure not completed")
                break
            case .PARAMETER_OUT_OF_RANGE:
                self.showErrorAlert(withMessage:"Parameter out of range")
                break;
            default:
                break
            }
        }
        
        if characteristic.UUID == cgmFeatureCharacteristicUUID {
            self.parseCGMFeatureCharacteristic()
        }
        
        if characteristic.UUID == cgmSessionStartTimeCharacteristicUUID {
            print("Start time did update")
        }
        
        if characteristic.UUID == cgmSessionRunTimeCharacteristicUUID {
            print("runtime did update")
        }
    }
    

}