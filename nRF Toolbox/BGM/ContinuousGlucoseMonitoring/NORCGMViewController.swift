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
    case action_START_SESSION = 0
    case action_STOP_SESSION  = 1
    case action_SET_TIME      = 2
}

class NORCGMViewController : NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, UITableViewDataSource, UIActionSheetDelegate {

    //MARK: - Class porperties
    var bluetoothManager : CBCentralManager?

    var dateFormat : DateFormatter

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
    
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        self.handleConnectionButtonTapped()
    }
    @IBAction func actionButtonTapped(_ sender: AnyObject) {
        self.handleActionButtonTapped()
    }
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        self.handleAboutButtonTapped()
    }

    //MARK: - UIViewController methods
    // Custom initialization
    required init?(coder aDecoder: NSCoder) {
        readings = NSMutableArray(capacity: 20)
        dateFormat = DateFormatter()
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
        self.verticalLabel.transform = CGAffineTransform(translationX: -185.0, y: 0.0).rotated(by: CGFloat(-M_PI_2))
        cbgmTableView.dataSource = self
    }
    
    func appdidEnterBackground() {
        let name = connectedPeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    func appDidBecomeActiveBackground(_ aNotification : Notification) {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func handleActionButtonTapped() {
        let actionSheet = UIActionSheet()
        actionSheet.delegate = self
        actionSheet.addButton(withTitle: "Start Session")
        actionSheet.addButton(withTitle: "Stop Session")
        actionSheet.addButton(withTitle: "Set Update Interval")
        actionSheet.destructiveButtonIndex = 1
        
        actionSheet.show(in: self.view)
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
        let arrayBytes = ((data as NSData?)?.bytes)!.assumingMemoryBound(to: UInt8.self)
        cgmFeatureData = NORCGMFeatureData(withBytes: UnsafeMutablePointer<UInt8>(mutating:arrayBytes))
    }

    func enableRecordButton() {
        recordButton.isEnabled = true
        recordButton.backgroundColor = UIColor.black
        recordButton.setTitleColor(UIColor.white, for: UIControlState())
    }
    
    func disableRecordButton() {
        recordButton.isEnabled = false
        recordButton.backgroundColor = UIColor.lightGray
        recordButton.setTitleColor(UIColor.lightText, for: UIControlState())
    }

    func clearUI() {
        readings?.removeAllObjects()
        cbgmTableView.reloadData()
        deviceName.text = "DEFAULT CGM"
        
        battery.tag = 0
        battery.setTitle("n/a", for:UIControlState())
    }
    
    func showErrorAlert(withMessage aMessage : String) {
        DispatchQueue.main.async(execute: {
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
        let connectionOptions = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)

        bluetoothManager?.connect(aPeripheral, options: connectionOptions as? [String : AnyObject])
    }

    //MARK: - Table View Datasource delegate methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (readings?.count)!
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aReading = readings?.object(at: (indexPath as NSIndexPath).row) as? NORCGMReading
        let aCell = tableView.dequeueReusableCell(withIdentifier: "CGMCell", for: indexPath) as! NORCGMItemCell

        aCell.type.text = aReading?.typeAsString()
        aCell.timestamp.text = dateFormat.string(from: Date.init(timeIntervalSinceNow: Double((aReading?.timeOffsetSinceSessionStart)!)))
        aCell.value.text = String(format: "%.0f", (aReading?.glucoseConcentration)!)
        aCell.unit.text = "mg/DL"
        
        return aCell
    }

    func showUserInputAlert(withMessage aMessage: String) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertView(title: "Input", message: aMessage, delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Set")
            alert.alertViewStyle = .plainTextInput
            alert.textField(at: 0)!.keyboardType = .numberPad
            alert.show()
        })
    }
    
    //MARK: - Segue navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier == "scan" && connectedPeripheral == nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "scan" || segue.identifier == "details" else {
            return
        }
        
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc = segue.destination
            let controller = nc.childViewControllerForStatusBarHidden as! NORScannerViewController

            controller.filterUUID = cbgmServiceUUID
            controller.delegate = self
        }
        
        if segue.identifier == "details" {
            let controller = segue.destination as! NORCGMDetailsViewController
            let aReading = readings!.object(at: ((cbgmTableView.indexPathForSelectedRow as NSIndexPath?)?.row)!)
            controller.reading = aReading as? NORCGMReading
        }
    }

    //MARK: - Action Sheet delegate methods
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        var accessParam : [UInt8] = []
        var size  : NSInteger = 0
        var clearList :Bool = true
        var targetCharacteristic : CBCharacteristic?
        
        switch viewActionTypes(rawValue:buttonIndex)! {
        case .action_START_SESSION:
            accessParam.append(NORCGMOpCode.start_SESSION.rawValue)
            size = 1
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic
            cgmActivityIndicator.startAnimating()
            clearList = false
            break
        case .action_STOP_SESSION:
            accessParam.append(NORCGMOpCode.stop_SESSION.rawValue)
            size = 1
            targetCharacteristic = cgmSpecificOpsControlPointCharacteristic
            cgmActivityIndicator.stopAnimating()
            clearList = false
            break
        case .action_SET_TIME:
            self.showUserInputAlert(withMessage: "Enter update interval in minutes")
            clearList = false
            break
        }
        
        if clearList {
            readings!.removeAllObjects()
            cbgmTableView.reloadData()
        }
        
        if size > 0 {
            
            let data = Data(bytes: &accessParam, count: size)
            print("Writing data: \(data) to \(targetCharacteristic!)")
            connectedPeripheral?.writeValue(data, for: targetCharacteristic!, type:.withResponse)
        }
    }

    //MARK: - UIAlertViewDelegate / Helpers
    func alertView(_ alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != 0 {
            var accessParam : [UInt8] = []
            let timeValue = Int(alertView.textField(at: 0)!.text!)
            accessParam.append(NORCGMOpCode.set_COMMUNICATION_INTERVAL.rawValue)
            accessParam.append(UInt8(timeValue!))
            let data = Data(bytes: &accessParam, count: 2)
            print("Writing data : \(data) to characteristic: \(cgmSpecificOpsControlPointCharacteristic)")
            connectedPeripheral?.writeValue(data, for: cgmSpecificOpsControlPointCharacteristic!, type: .withResponse)
        }
    }
    //MARK: - Central Manager delegate methods
    
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
            self.enableRecordButton()
            //Following if condition display user permission alert for background notification
            if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
            }

            NotificationCenter.default.addObserver(self, selector: #selector(self.appdidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActiveBackground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        });
        
        // Peripheral has connected. Discover required services
        connectedPeripheral = peripheral
        peripheral.discoverServices([cbgmServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to the peripheral failed. Try again")
            self.connectionButton.setTitle("CONNCET", for: UIControlState())
            self.connectedPeripheral = nil
            self.disableRecordButton()
            self.clearUI()
        });
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
            
            self.disableRecordButton()
            self.clearUI()
            NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
            NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        })
    }
    
    //MARK: - CBPeripheralDelegate methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService in peripheral.services! {
            // Discovers the characteristics for a given service
            if  aService.uuid == cbgmServiceUUID {
                peripheral.discoverCharacteristics(
                    [   cgmGlucoseMeasurementCharacteristicUUID,
                        cgmGlucoseMeasurementContextCharacteristicUUID,
                        cgmRecordAccessControlPointCharacteristicUUID,
                        cgmFeatureCharacteristicUUID,
                        cgmStatusCharacteristicUUID,
                        cgmSessionStartTimeCharacteristicUUID,
                        cgmSessionRunTimeCharacteristicUUID,
                        cgmSpecificOpsControlPointCharacteristicUUID
                    ], for: aService)
            } else if aService.uuid == batteryServiceUUID {
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
        
        // Characteristics for one of those services has been found
        if service.uuid == cbgmServiceUUID {
            for characteristic in service.characteristics! {
                peripheral.setNotifyValue(true, for: characteristic)

                if characteristic.uuid == cgmFeatureCharacteristicUUID {
                    cgmFeatureCharacteristic = characteristic
                    peripheral.readValue(for: cgmFeatureCharacteristic!)
                }
                if characteristic.uuid == cgmRecordAccessControlPointCharacteristicUUID {
                    cgmRecordAccessControlPointCharacteristic = characteristic
                }
                if characteristic.uuid == cgmSpecificOpsControlPointCharacteristicUUID {
                    cgmSpecificOpsControlPointCharacteristic = characteristic
                }
            }
        } else if service.uuid == batteryServiceUUID {
            for characteristic in service.characteristics! {
                if characteristic.uuid == batteryLevelCharacteristicUUID {
                    peripheral.readValue(for: characteristic)
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
        
        // Decode the characteristic data
        let data = characteristic.value
        var array = UnsafeMutablePointer<UInt8>(mutating: (data! as NSData).bytes.bindMemory(to: UInt8.self, capacity: data!.count))
        if characteristic.uuid == batteryLevelCharacteristicUUID {
            let batteryLevel = NORCharacteristicReader.readUInt8Value(ptr: &array)
            let text = "\(batteryLevel)%"
            
            // Scanner uses other queue to send events. We must edit UI in the main queue
            DispatchQueue.main.async(execute: {
                self.battery.setTitle(text, for: .disabled)
            })
            
            if battery.tag == 0 {
                // If battery level notifications are available, enable them
                if characteristic.properties.contains(CBCharacteristicProperties.notify) {
                    self.battery.tag = 1 // mark that we have enabled notifications
                    // Enable notification on data characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
        if characteristic.uuid == cgmGlucoseMeasurementCharacteristicUUID {
            DispatchQueue.main.async(execute: {
                let reading = NORCGMReading(withBytes: array)
                if self.cgmFeatureData != nil {
                    reading.cgmFeatureData = self.cgmFeatureData
                }
                if self.readings!.contains(reading) {
                    // If the reading has been found (the same reading has the same sequence number), replace it with the new one
                    // The indexIfObjext method uses isEqual method from GlucodeReading (comparing by sequence number only)
                    self.readings!.replaceObject(at: self.readings!.index(of: reading), with: reading)
                } else {
                    // If not, just add the new one to the array
                    self.readings!.add(reading)
                }
                self.cbgmTableView.reloadData()
            })
        }
        if characteristic.uuid == cgmSpecificOpsControlPointCharacteristicUUID {
            let responseCode = array[2]
            switch NORCGMOpcodeResponseCodes(rawValue: responseCode)! {
            case .op_CODE_NOT_SUPPORTED:
                self.showErrorAlert(withMessage:"Operation not supported")
                break;
            case .success:
                print("Success")
                break;
            case .invalid_OPERAND:
                self.showErrorAlert(withMessage:"Invalid Operand")
                break
            case .procedure_NOT_COMPLETED:
                self.showErrorAlert(withMessage:"Procedure not completed")
                break
            case .parameter_OUT_OF_RANGE:
                self.showErrorAlert(withMessage:"Parameter out of range")
                break;
            default:
                break
            }
        }
        
        if characteristic.uuid == cgmFeatureCharacteristicUUID {
            self.parseCGMFeatureCharacteristic()
        }
        
        if characteristic.uuid == cgmSessionStartTimeCharacteristicUUID {
            print("Start time did update")
        }
        
        if characteristic.uuid == cgmSessionRunTimeCharacteristicUUID {
            print("runtime did update")
        }
    }
    

}
