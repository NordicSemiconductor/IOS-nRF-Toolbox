//
//  NORPRoximityViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 10/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

class NORProximityViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, CBPeripheralManagerDelegate {
    
    //MARK: - Class Properties
    var bluetoothManager                        : CBCentralManager?
    var proximityImmediateAlertServiceUUID      : CBUUID
    var proximityLinkLossServiceUUID            : CBUUID
    var proximityAlertLevelCharacteristicUUID   : CBUUID
    var batteryServiceUUID                      : CBUUID
    var batteryLevelCharacteristicUUID          : CBUUID
    var isImmidiateAlertOn                      : Bool?
    var isBackButtonPressed                     : Bool?
    var proximityPeripheral                     : CBPeripheral?
    var peripheralManager                       : CBPeripheralManager?
    var immidiateAlertCharacteristic            : CBCharacteristic?
    var audioPlayer                             : AVAudioPlayer?

    //MARK: - View Outlets
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var findmeButton: UIButton!
    @IBOutlet weak var connectionButton: UIButton!
    
    //MARK: - View Actions
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        if proximityPeripheral != nil {
            bluetoothManager?.cancelPeripheralConnection(proximityPeripheral!)
        }
    }
    
    @IBAction func findmeButtonTapped(_ sender: AnyObject) {
        if self.immidiateAlertCharacteristic != nil {
            if isImmidiateAlertOn == true {
                self.immidiateAlertOff()
            } else {
                self.immidiateAlertOn()
            }
        }
    }
    
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .proximity))
    }

    
    //MARK: - UIVIew Delegate
    required init?(coder aDecoder: NSCoder) {
        // Custom initialization
        proximityImmediateAlertServiceUUID      = CBUUID(string: NORServiceIdentifiers.proximityImmediateAlertServiceUUIDString)
        proximityLinkLossServiceUUID            = CBUUID(string: NORServiceIdentifiers.proximityLinkLossServiceUUIDString)
        proximityAlertLevelCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.proximityAlertLevelCharacteristicUUIDString)
        batteryServiceUUID                      = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID          = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        self.verticalLabel.transform = CGAffineTransform(translationX: -110.0, y: 0.0).rotated(by: CGFloat(-M_PI_2))
        self.immidiateAlertCharacteristic = nil
        isImmidiateAlertOn = false
        isBackButtonPressed = false;
        self.initGattServer()
        self.initSound()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if proximityPeripheral != nil && isBackButtonPressed == true {
            bluetoothManager?.cancelPeripheralConnection(proximityPeripheral!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - Class Implementation
    func initSound() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
            print("Could not init AudioSession!")
            return
        }

        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "high", ofType: "mp3")!)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch _ {
            print("Could not intialize AudioPlayer")
            return
        }
        audioPlayer?.prepareToPlay()
    }
    
    func enableFindmeButton() {
        findmeButton.isEnabled         = true
        findmeButton.backgroundColor = UIColor.black
        findmeButton.setTitleColor(UIColor.white, for: UIControlState())
    }
    
    func disableFindmeButton() {
        findmeButton.isEnabled = false
        findmeButton.backgroundColor = UIColor.lightGray
        findmeButton.setTitleColor(UIColor.lightText, for: UIControlState())
    }

    func initGattServer() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func addServices() {
        let service = CBMutableService(type: CBUUID(string:"1802"), primary: true)
        let characteristic = self.createCharacteristic()
        service.characteristics = [characteristic]
        self.peripheralManager?.add(service)
    }
        
    func createCharacteristic() -> CBMutableCharacteristic {
        let properties : CBCharacteristicProperties  = CBCharacteristicProperties.writeWithoutResponse
        let permissions : CBAttributePermissions     = CBAttributePermissions.writeable
        let characteristicType : CBUUID              = CBUUID(string:"2A06")
        let characteristic : CBMutableCharacteristic = CBMutableCharacteristic(type: characteristicType, properties: properties, value: nil, permissions: permissions)
        
        return characteristic
    }

    func immidiateAlertOn() {
        if self.immidiateAlertCharacteristic != nil {
            var val : UInt8 = 2
            let data = Data(bytes: &val, count: 1)
            proximityPeripheral?.writeValue(data, for: immidiateAlertCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
            isImmidiateAlertOn = true
            findmeButton.setTitle("SilentMe", for: UIControlState())
        }
    }
    
    func immidiateAlertOff() {
        if self.immidiateAlertCharacteristic != nil {
            var val : UInt8 = 0
            let data = Data(bytes: &val, count: 1)
            proximityPeripheral?.writeValue(data, for: immidiateAlertCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
            isImmidiateAlertOn = false
            findmeButton.setTitle("FindMe", for: UIControlState())
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
    func playLoopingSound() {
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.play()
    }
    
    func playSoundOnce() {
        audioPlayer?.play()
    }

    func clearUI() {
        deviceName.text = "DEFAULT PROXIMITY"
        battery.setTitle("n/a", for:UIControlState.disabled)
        battery.tag = 0
        lockImage.isHighlighted = false
        isImmidiateAlertOn = false
        self.immidiateAlertCharacteristic = nil
    }
    
    func applicationDidEnterBackgroundCallback() {
        let name = proximityPeripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name).")
    }
    
    func applicationDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }

    //MARK: - Segue Methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier != "scan" || proximityPeripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc = segue.destination as! UINavigationController
            let controller = nc.childViewControllerForStatusBarHidden as! NORScannerViewController
            controller.filterUUID = proximityLinkLossServiceUUID
            controller.delegate = self
        }
    }
    
    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager
        bluetoothManager!.delegate = self
        
        // The sensor has been selected, connect to it
        proximityPeripheral = aPeripheral
        proximityPeripheral!.delegate = self
        bluetoothManager?.connect(proximityPeripheral!, options: [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(value: true as Bool)])
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
            self.lockImage.isHighlighted = true
            self.enableFindmeButton()
        })
        //Following if condition display user permission alert for background notification
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))){
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        if NORAppUtilities.isApplicationInactive() {
            NORAppUtilities.showBackgroundNotification(message: "\(self.proximityPeripheral?.name) is within range!")
        }
        
        peripheral.discoverServices([proximityLinkLossServiceUUID, proximityImmediateAlertServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to the peripheral failed. Try again")
            self.connectionButton.setTitle("CONNECT", for: UIControlState())
            self.proximityPeripheral = nil
            self.disableFindmeButton()
            self.clearUI()
        })
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral disconnected or out of range!")
        DispatchQueue.main.async(execute: {
            let name = peripheral.name ?? "Peripheral"
            if error != nil {
                self.lockImage.isHighlighted = false
                self.disableFindmeButton()
                self.bluetoothManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(value: true as Bool)])
                let message = "\(name) is out of range!"
                if NORAppUtilities.isApplicationInactive() {
                    NORAppUtilities.showBackgroundNotification(message: message)
                } else {
                    NORAppUtilities.showAlert(title: "PROXIMITY", andMessage: message)
                }
                self.playSoundOnce()
            } else {
                self.connectionButton.setTitle("CONNECT", for: UIControlState())
                if NORAppUtilities.isApplicationInactive() {
                    NORAppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
                }
                
                self.proximityPeripheral = nil
                self.clearUI()
                NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            }
        })
    }

    //MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return;
        }
        
        for aService : CBService in (peripheral.services)! {
            if aService.uuid == proximityLinkLossServiceUUID {
                print("Link loss service is found")
                peripheral.discoverCharacteristics([proximityAlertLevelCharacteristicUUID], for: aService)
            } else if aService.uuid == proximityImmediateAlertServiceUUID {
                print("Immediate alert service is found")
                peripheral.discoverCharacteristics([proximityAlertLevelCharacteristicUUID], for: aService)
            }else if aService.uuid == batteryServiceUUID {
                print("Battery service is found")
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
        
        if service.uuid == proximityLinkLossServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == proximityAlertLevelCharacteristicUUID {
                    var val = UInt8(1)
                    let data = Data(bytes: &val, count: 1)
                    peripheral.writeValue(data, for: aCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        } else if service.uuid == proximityImmediateAlertServiceUUID {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid == proximityAlertLevelCharacteristicUUID {
                    immidiateAlertCharacteristic = aCharacteristic
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
        
        print(characteristic.uuid)
        DispatchQueue.main.async(execute: {
            if characteristic.uuid == self.batteryLevelCharacteristicUUID {
                let value = characteristic.value!
                let array = UnsafeMutablePointer<UInt8>(mutating: (value as NSData).bytes.bindMemory(to: UInt8.self, capacity: value.count))
                let batteryLevel = UInt8(array[0])
                let text = "\(batteryLevel)%"
                self.battery.setTitle(text, for: UIControlState.disabled)

                if self.battery.tag == 0 {
                    // If battery level notifications are available, enable them
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) > 0 {
                        //Mark that we have enabled notifications
                        self.battery.tag = 1
                        //Enable notification on data characteristic
                        self.proximityPeripheral?.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        })
    }
    //MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch (peripheral.state) {
        case .poweredOff:
            print("PeripheralManagerState is Off")
            break;
        case .poweredOn:
            print("PeripheralManagerState is on");
            self.addServices()
            break;
        default:
            break;
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("Error while adding peripheral service: \(error!.localizedDescription)")
            return
        }
        print("PeripheralManager added sercvice successfully")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let attributeRequest = requests[0]
        
        if attributeRequest.characteristic.uuid == CBUUID(string: "2A06") {
           let data        = attributeRequest.value!
           let array       = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))
           let alertLevel  = array[0]

            switch alertLevel {
            case 0:
                print("No Alert")
                stopSound()
                break
            case 1:
                print("Low Alert")
                playLoopingSound()
                break
            case 2:
                print("High Alert")
                playSoundOnce()
                break
            default:
                break
            }
        }

    }
}
