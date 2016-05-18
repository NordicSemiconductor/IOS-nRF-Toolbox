//
//  NORBluetoothManager.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 06/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol NORBluetoothManagerDelegate {
    
    func didConnectPeripheral(deviceName aName : String)
    func didDisconnectPeripheral()
    func peripheralReady()
    func peripheralNotSupported()
    
}

class NORBluetoothManager: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    //MARK: - Delegate Properties
    var delegate : NORBluetoothManagerDelegate?
    var logger   : NORLogger?
    
    //MARK: - Class Properties
    var UARTServiceUUID             : CBUUID?
    var UARTRXCharacteristicUUID    : CBUUID?
    var UARTTXCharacteristicUUID    : CBUUID?
    
    var centralManager              : CBCentralManager?
    var bluetoothPeripheral         : CBPeripheral?
    var uartRXCharacteristic        : CBCharacteristic?
    var uartTXCharacteristic        : CBCharacteristic?

    //MARK: - Implementation
    required init(withManager aManager : CBCentralManager) {
        super.init()
        // ret: instancetype
        UARTServiceUUID          = CBUUID(string: NORServiceIdentifiers.uartServiceUUIDString)
        UARTTXCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.uartTXCharacteristicUUIDString)
        UARTRXCharacteristicUUID = CBUUID(string: NORServiceIdentifiers.uartRXCharacteristicUUIDString)
        centralManager = aManager
        centralManager?.delegate = self
    }
    
    //MARK: - BluetoothManager API
    func connectPeripheral(peripheral aPeripheral : CBPeripheral) {
        // we assign the bluetoothPeripheral property after we establish a connection, in the callback
        log(withLevel: .VerboseLogLevel, andMessage: "Connecting to: \(aPeripheral.name!) ...")
        log(withLevel: .DebugLogLevel, andMessage: "centralManager.connectPeripheral(peripheral, options:nil")
        centralManager?.connectPeripheral(aPeripheral, options: nil)
    }
    
    func cancelPeriphralConnection() {
        guard bluetoothPeripheral != nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Peripheral not set")
            return
        }
        log(withLevel: .VerboseLogLevel, andMessage: "Disconnecting...")
        log(withLevel: .DebugLogLevel, andMessage: "centralManager.cancelPeriphralConnection(peripheral)")
        centralManager?.cancelPeripheralConnection(bluetoothPeripheral!)
    }
    
    
    func isConnected() -> Bool {
        return bluetoothPeripheral != nil
    }
    
    func send(text aText : String) {
        /*
         * This method sends the given test to the UART RX characteristic.
         * Depending on whether the characteristic has the Write Without Response or Write properties the behaviour is different.
         * In the latter case the Long Write may be used. To enable it you have to change the flag below.
         * Otherwise, in both cases, texts longer than 20 bytes (not characters) will be splitted into up-to 20-byte packets.
         */
        guard self.uartRXCharacteristic != nil else {
            log(withLevel: .WarningLogLevel, andMessage: "UART RX Characteristic not set!")
            return
        }
        
        // Check what kind of Write Type is supported. By default it will try Without Response.
        var type = CBCharacteristicWriteType.WithoutResponse
        if (self.uartRXCharacteristic?.properties.rawValue)! & CBCharacteristicProperties.Write.rawValue > 0 {
            type = CBCharacteristicWriteType.WithResponse
        }

        // In case of Write Without Response the text needs to be splited in up-to 20-bytes packets.
        // When Write Request (with response) is used, the Long Write may be used. It will be handled automatically by the iOS, but must be supported on the device side.
        // If your device does support Long Write, change the flag here.
        let longWriteSupported = false
        
        // The following code will split the text to packets
        var buffer = UnsafeMutablePointer<CChar>(aText.cStringUsingEncoding(NSUTF8StringEncoding)!)
        print(buffer)
        var len = aText.dataUsingEncoding(NSUTF8StringEncoding)?.length
        
        while(buffer != nil){
            var part : String
            if len > 20 && (type == CBCharacteristicWriteType.WithoutResponse || longWriteSupported == false) {
                // If the text contains national letters they may be 2-byte long. It may happen that only 19 bytes can be send so that non of them is splited into 2 packets.
                var builder = NSMutableString(bytes: buffer, length: 20, encoding: NSUTF8StringEncoding)
                if builder != nil {
                    // A 20-bute string has been created successfully
                    buffer  = buffer + 20
                    len     = len! - 20
                } else {
                    // We have to create 19-byte string. Let's ignore some stranger UTF-8 characters that have more than 2 bytes...
                    builder = NSMutableString(bytes: buffer, length: 19, encoding: NSUTF8StringEncoding)
                    buffer = buffer + 19
                    len    = len! - 19
                }
                
                part = String(builder)
            } else {
                part = String(buffer)
                buffer = nil
            }
            self.send(text: part, withType: type)
        }
    }
    
    /*!
     * Sends the given text to the UART RX characteristic using the given write type.
     */
    func send(text aText : String, withType aType : CBCharacteristicWriteType) {
        var typeAsString = "CBCharacteristicWriteWithoutResponse"
        if (self.uartRXCharacteristic?.properties.rawValue)! & CBCharacteristicProperties.Write.rawValue > 0 {
            typeAsString = "CBCharacteristicWriteWithResponse"
        }
        
        let data = aText.dataUsingEncoding(NSUTF8StringEncoding)
        
        //do some logging
        log(withLevel: .VerboseLogLevel, andMessage: "Writing to characteristic: \(uartRXCharacteristic?.UUID.UUIDString)")
        log(withLevel: .DebugLogLevel, andMessage: "centralManager.writeValue(\(data), forCharacteristic:\(uartRXCharacteristic?.UUID.UUIDString), type:\(typeAsString)")
        self.bluetoothPeripheral?.writeValue(data!, forCharacteristic: self.uartRXCharacteristic!, type: aType)
        // The transmitted data is not available after the method returns. We have to log the text here.
        // The callback peripheral:didWriteValueForCharacteristic:error: is called only when the Write Request type was used,
        // but even if, the data is not available there.
        log(withLevel: .AppLogLevel, andMessage: "\(aText) sent.")
    }

    
    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        var state : String
        switch(central.state){
        case .PoweredOn:
            state = "Powered ON"
            break
        case .PoweredOff:
            state = "Powered OFF"
            break
        case .Resetting:
            state = "Resetting"
            break
        case .Unauthorized:
            state = "Unautthorized"
            break
        case .Unsupported:
            state = "Unsupported"
            break
        case .Unknown:
            state = "Unknown"
            break
        }
        
        self.log(withLevel: .DebugLogLevel, andMessage: String(format: "[Callback] Central Manager did update state to: %@", state))
    }
    
    //MARK: - Logger API

    func log(withLevel aLevel : NORLOGLevel, andMessage aMessage : String) {
        guard logger != nil else {
            return
        }
        logger?.log(level: aLevel,message: aMessage)
    }
    
    func logError(error anError : NSError) {
        guard logger != nil else {
            return
        }
        logger?.log(level: .ErrorLogLevel, message: String(format: "Error %ld: %@", anError.code, anError.localizedDescription))
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        self.log(withLevel: .DebugLogLevel, andMessage: String(format: "[Callback] Central manager did connect peripheral"))
        self.log(withLevel: .InfoLogLevel, andMessage: String("Connected to : \(peripheral.name)"))
        
        bluetoothPeripheral = peripheral
        bluetoothPeripheral?.delegate = self
        delegate?.didConnectPeripheral(deviceName: peripheral.name!)
        log(withLevel: .VerboseLogLevel, andMessage: "Discovering services...")
        log(withLevel: .DebugLogLevel, andMessage: String("Peripheral.discoverServices(\(UARTServiceUUID?.UUIDString))"))
        peripheral.discoverServices([UARTServiceUUID!])
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        guard error == nil else {
            log(withLevel: .DebugLogLevel, andMessage: "[Callback] CentralManager did disconnect peripheral")
            logError(error: error!)
            return
        }
        log(withLevel: .DebugLogLevel, andMessage: "[Callback] Central Manager did disconnect peripheral successfully")
        log(withLevel: .InfoLogLevel, andMessage: "Disconnected")
        
        delegate?.didDisconnectPeripheral()
        bluetoothPeripheral?.delegate = nil
        bluetoothPeripheral = nil
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        guard error == nil else {
            log(withLevel: .DebugLogLevel, andMessage: "[Callback] Central Manager did fail to connect to peripheral")
            logError(error: error!)
            return
        }
        log(withLevel: .DebugLogLevel, andMessage: "[Callback] Central Manager did fail to connect to peripheral without errors")
        
        delegate?.didDisconnectPeripheral()
        bluetoothPeripheral?.delegate = nil
        bluetoothPeripheral = nil
    }

    //MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Service discovery failed")
            logError(error: error!)
            //TODO: Disconnect?
            return
        }
        
        log(withLevel: .InfoLogLevel, andMessage: "Services discovered")
        
        for aService: CBService in peripheral.services! {
            if aService.UUID.isEqual(UARTServiceUUID) {
                log(withLevel: .VerboseLogLevel, andMessage: "Nordic UART Service found")
                log(withLevel: .VerboseLogLevel, andMessage: "Discovering characteristics...")
                log(withLevel: .DebugLogLevel, andMessage: "peripheral.discoverCharacteristics(nil, forService:\(aService.UUID.UUIDString)")
                bluetoothPeripheral?.discoverCharacteristics(nil, forService: aService)
                return
            }
        }
        
        //No UART service discovered
        log(withLevel: .WarningLogLevel, andMessage: "UART Service not found. Try to turn bluetooth Off and On again to clear the cache.")
        delegate?.peripheralNotSupported()
        cancelPeriphralConnection()
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard error == nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Characteristics discovery failed")
            logError(error: error!)
            return
        }
        log(withLevel: .InfoLogLevel, andMessage: "Characteristics discovererd")
        
        if service.UUID.isEqual(UARTServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID.isEqual(UARTTXCharacteristicUUID) {
                    log(withLevel: .VerboseLogLevel, andMessage: "TX Characteristic found")
                    uartTXCharacteristic = aCharacteristic
                }else if aCharacteristic.UUID.isEqual(UARTRXCharacteristicUUID) {
                    log(withLevel: .VerboseLogLevel, andMessage: "RX Characteristic found")
                    uartRXCharacteristic = aCharacteristic
                }
            }
            //Enable notifications on TX Characteristic
            if(uartTXCharacteristic != nil && uartRXCharacteristic != nil) {
                log(withLevel: .VerboseLogLevel, andMessage: "Enableg notifications for \(uartTXCharacteristic?.UUID.UUIDString)")
                log(withLevel: .DebugLogLevel, andMessage: "peripheral.setNotifyValue(true, forCharacteristic: \(uartTXCharacteristic?.UUID.UUIDString)")
                bluetoothPeripheral?.setNotifyValue(true, forCharacteristic: uartTXCharacteristic!)
            }else{
                log(withLevel: .WarningLogLevel, andMessage: "UART service does not have required characteristics. Try to turn Bluetooth OFF and ON again to clear cache.")
                delegate?.peripheralNotSupported()
                cancelPeriphralConnection()
            }
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Enabling notifications failed")
            logError(error: error!)
            return
        }
        
        if characteristic.isNotifying {
            log(withLevel: .InfoLogLevel, andMessage: "Notifications enabled for characteristic : \(characteristic.UUID.UUIDString)")
        }else{
            log(withLevel: .InfoLogLevel, andMessage: "Notifications disabled for characteristic : \(characteristic.UUID.UUIDString)")
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Writing value to characteristic has failed")
            logError(error: error!)
            return
        }
        log(withLevel: .InfoLogLevel, andMessage: "Data written to characteristic: \(characteristic.UUID.UUIDString)")
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        guard error == nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Writing value to descriptor has failed")
            logError(error: error!)
            return
        }
        log(withLevel: .InfoLogLevel, andMessage: "Data written to descriptor: \(descriptor.UUID.UUIDString)")
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            log(withLevel: .WarningLogLevel, andMessage: "Updating characteristic has failed")
            logError(error: error!)
            return
        }
        log(withLevel: .InfoLogLevel, andMessage: "Notification received from: \(characteristic.UUID.UUIDString), with value: \(characteristic.value)")
        log(withLevel: .AppLogLevel, andMessage: "\(characteristic.value) received")
    }

//    //MARK: - NORBluetoothManagerDelegate
//    func didConnectPeripheral(deviceName aName: String) {
//        
//    }
//    
//    func didDisconnectPeripheral() {
//        
//    }
//    
//    func peripheralReady() {
//        
//    }
//    
//    func peripheralNotSupported() {
//
//    }
}
