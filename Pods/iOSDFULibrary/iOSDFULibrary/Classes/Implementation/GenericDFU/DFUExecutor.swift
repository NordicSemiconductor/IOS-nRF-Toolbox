//
//  DFUExecutor.swift
//  Pods
//
//  Created by Mostafa Berg on 17/06/16.
//
//

import CoreBluetooth

class DFUExecutor : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    fileprivate var delegate:DFUServiceDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.delegate
    }

    fileprivate var progressDelegate:DFUProgressDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.progressDelegate
    }

    internal var secureDFUController : SecureDFUServiceController?
    internal var legacyDFUController : LegacyDFUServiceController?
    internal var initiator           : DFUServiceInitiator
    internal var firmware            : DFUFirmware
    internal var peripheral          : CBPeripheral
    internal var isSecureDFU         : Bool?
    internal var centralManager      : CBCentralManager

    init(_ initiator:DFUServiceInitiator) {
        self.initiator  = initiator
        self.firmware   = initiator.file!
        self.peripheral = initiator.target
        self.centralManager = initiator.centralManager
    }

    //MARK: - DFU Executor implementation
    
    var paused:Bool {
        if self.isSecureDFU! {
            return (secureDFUController?.paused)!
        }else{
            return (legacyDFUController?.paused)!
        }
    }
    
    var aborted:Bool {
        if self.isSecureDFU! {
            return (secureDFUController?.aborted)!
        }else{
            return (legacyDFUController?.aborted)!
        }
    }
    
    func didDiscoverDFUService(_ secureDFU : Bool) {
        self.isSecureDFU = secureDFU
        if isSecureDFU! {
            initiator.logger?.logWith(.verbose, message: "Did discover secure DFU service")
            self.startSecureDFU()
        } else {
            initiator.logger?.logWith(.verbose, message: "Did discover legacy DFU service")
            self.startLegacyDFU()
        }
    }

    func startSecureDFU() {
        initiator.logger?.logWith(.verbose, message: "Starting Secure DFU Service initiator")
        self.initiator.onPeripheralDFUDiscovery(true)
        let dfuInitiator = SecureDFUServiceInitiator(centralManager: self.centralManager, target: self.peripheral)
        _ = dfuInitiator.withFirmwareFile(firmware)
        dfuInitiator.delegate = initiator.delegate
        dfuInitiator.progressDelegate = initiator.progressDelegate
        dfuInitiator.logger = initiator.logger
        dfuInitiator.packetReceiptNotificationParameter = self.initiator.packetReceiptNotificationParameter
        dfuInitiator.peripheralSelector = DFUPeripheralSelector(secureDFU: true)
        initiator.logger?.logWith(.verbose, message: "Instantiated Secure DFU peripheral selector")
        self.secureDFUController = dfuInitiator.start()
    }
    
    func startLegacyDFU() {
        
        initiator.logger?.logWith(.verbose, message: "Starting legacy DFU Service initiator")
        self.initiator.onPeripheralDFUDiscovery(true)
        let dfuInitiator = LegacyDFUServiceInitiator(centralManager: self.centralManager, target: self.peripheral)
        _ = dfuInitiator.withFirmwareFile(firmware)
        dfuInitiator.delegate = initiator.delegate
        dfuInitiator.progressDelegate = initiator.progressDelegate
        dfuInitiator.logger = initiator.logger
        dfuInitiator.peripheralSelector = DFUPeripheralSelector(secureDFU: false)
        dfuInitiator.packetReceiptNotificationParameter = self.initiator.packetReceiptNotificationParameter
        initiator.logger?.logWith(.verbose, message: "Instantiated Legacy DFU peripheral selector")
        self.legacyDFUController = dfuInitiator.start()
    }
    
    func deviceNotSupported(){
        self.delegate?.didErrorOccur(DFUError.deviceNotSupported, withMessage: "device does not have DFU enabled")
        self.delegate?.didStateChangedTo(.disconnecting)
    }
    
    //MARK: - DFU Controller methods
    func start() {
        DispatchQueue.main.async(execute: {
            self.delegate?.didStateChangedTo(DFUState.connecting)
        })
        
        let centralManager = self.initiator.centralManager
        centralManager.delegate = self
        if peripheral.state == .connected {
            self.initiator.logger?.logWith(.verbose, message: "\(self.peripheral.name!) is already connected, starting DFU Process")
            setConnectedPeripheral(peripheral: peripheral)
        }else{
            self.initiator.logger?.logWith(.verbose, message: "Connecting to \(self.peripheral.name!)")
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func pause() -> Bool {
        if self.isSecureDFU == nil {
            return false
        }
        if self.isSecureDFU! {
            return (self.secureDFUController?.pause())!
        }else{
            return (self.legacyDFUController?.pause())!
        }
    }
    
    func resume() -> Bool {
        if self.isSecureDFU! {
            return (self.secureDFUController?.resume())!
        }else{
            return (self.legacyDFUController?.resume())!
        }
    }
    
    func abort() -> Bool {
        if self.isSecureDFU! {
            return (self.secureDFUController?.abort())!
        }else{
            return (self.legacyDFUController?.abort())!
        }
    }

    func setConnectedPeripheral(peripheral : CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil) //Discover all services
        self.initiator.logger?.logWith(.verbose, message: "Discovering all services for peripheral \(self.peripheral.name!)")
    }

    //MARK: - CBCentralManager delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        if central.state != .poweredOn {
            self.delegate?.didErrorOccur(DFUError.failedToConnect, withMessage: "The bluetooth radio is powered off")
            self.delegate?.didStateChangedTo(.failed)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //Discover services as soon as we connect to peripheral
        setConnectedPeripheral(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            self.delegate?.didErrorOccur(DFUError.deviceDisconnected, withMessage: "Error while disconnecting from peripheral: \(error)")
            self.delegate?.didStateChangedTo(.failed)
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            self.delegate?.didErrorOccur(DFUError.failedToConnect, withMessage: "Error while connecting to peripheral: \(error)")
            self.delegate?.didStateChangedTo(.failed)
    }

    //MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for aService in peripheral.services! {
            initiator.logger?.logWith(.verbose, message: "Discovered Service \(aService.uuid) on peripheral \(peripheral)")
            if aService.uuid == SecureDFUService.UUID {
                //First priority if SDFU
                self.didDiscoverDFUService(true)
                return
            }
            
            if aService.uuid == LegacyDFUService.UUID {
                //Second priority is legacy DFU
                self.didDiscoverDFUService(false)
                return
            }
        }
        //No DFU found at this point, disconnect and report
        self.deviceNotSupported()
    }

}
