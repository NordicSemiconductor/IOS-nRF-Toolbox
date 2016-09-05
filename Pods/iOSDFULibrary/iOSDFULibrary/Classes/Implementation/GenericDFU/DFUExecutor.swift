//
//  DFUExecutor.swift
//  Pods
//
//  Created by Mostafa Berg on 17/06/16.
//
//

import CoreBluetooth

class DFUExecutor : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var delegate:DFUServiceDelegate? {
        // The delegate may change during DFU operation (setting a new one in the initiator). Let's allways use the current one.
        return initiator.delegate
    }

    private var progressDelegate:DFUProgressDelegate? {
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
    
    func didDiscoverDFUService(secureDFU : Bool) {
        self.isSecureDFU = secureDFU
        if isSecureDFU! {
            initiator.logger?.logWith(.Verbose, message: "Did discover secure DFU service")
            self.startSecureDFU()
        } else {
            initiator.logger?.logWith(.Verbose, message: "Did discover legacy DFU service")
            self.startLegacyDFU()
        }
    }

    func startSecureDFU() {
        initiator.logger?.logWith(.Verbose, message: "Starting Secure DFU Service initiator")
        self.initiator.onPeripheralDFUDiscovery(true)
        let dfuInitiator = SecureDFUServiceInitiator(centralManager: self.centralManager, target: self.peripheral)
        dfuInitiator.withFirmwareFile(firmware)
        dfuInitiator.delegate = initiator.delegate
        dfuInitiator.progressDelegate = initiator.progressDelegate
        dfuInitiator.logger = initiator.logger
        dfuInitiator.peripheralSelector = DFUPeripheralSelector(secureDFU: true)
        initiator.logger?.logWith(.Verbose, message: "Instantiated Secure DFU peripheral selector")
        self.secureDFUController = dfuInitiator.start()
    }
    
    func startLegacyDFU() {
        initiator.logger?.logWith(.Verbose, message: "Starting legacy DFU Service initiator")
        self.initiator.onPeripheralDFUDiscovery(true)
        let dfuInitiator = LegacyDFUServiceInitiator(centralManager: self.centralManager, target: self.peripheral)
        dfuInitiator.withFirmwareFile(firmware)
        dfuInitiator.delegate = initiator.delegate
        dfuInitiator.progressDelegate = initiator.progressDelegate
        dfuInitiator.logger = initiator.logger
        dfuInitiator.peripheralSelector = DFUPeripheralSelector(secureDFU: false)
        initiator.logger?.logWith(.Verbose, message: "Instantiated Legacy DFU peripheral selector")
        self.legacyDFUController = dfuInitiator.start()
    }
    
    func deviceNotSupported(){
        self.delegate?.didErrorOccur(DFUError.DeviceNotSupported, withMessage: "device does not have DFU enabled")
        self.delegate?.didStateChangedTo(.Disconnecting)
    }
    
    //MARK: - DFU Controller methods
    func start() {
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.didStateChangedTo(DFUState.Connecting)
        })
        
        let centralManager = self.initiator.centralManager
        centralManager.delegate = self
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func pause() -> Bool {
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
    
    func abort() {
        if self.isSecureDFU! {
            self.secureDFUController?.abort()
        }else{
            self.legacyDFUController?.abort()
        }
    }

    //MARK: - CBCentralManager delegate
    func centralManagerDidUpdateState(central: CBCentralManager){
        if central.state != CBCentralManagerState.PoweredOn {
            self.delegate?.didErrorOccur(DFUError.FailedToConnect, withMessage: "The bluetooth radio is powered off")
            self.delegate?.didStateChangedTo(.Failed)
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        //Discover services as soon as we connect to peripheral
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil) //Discover all services
        self.initiator.logger?.logWith(.Verbose, message: "Discovering all services for peripheral \(self.peripheral)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        guard error == nil else {
            self.delegate?.didErrorOccur(DFUError.DeviceDisconnected, withMessage: "Error while disconnecting from peripheral: \(error)")
            self.delegate?.didStateChangedTo(.Failed)
            return
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
            self.delegate?.didErrorOccur(DFUError.FailedToConnect, withMessage: "Error while connecting to peripheral: \(error)")
            self.delegate?.didStateChangedTo(.Failed)
    }

    //MARK: - CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for aService in peripheral.services! {
            initiator.logger?.logWith(.Verbose, message: "Discovered Service \(aService.UUID) on peripheral \(peripheral)")
            if aService.UUID == SecureDFUService.UUID {
                //First priority if SDFU
                self.didDiscoverDFUService(true)
                return
            }
            
            if aService.UUID == LegacyDFUService.UUID {
                //Second priority is legacy DFU
                self.didDiscoverDFUService(false)
                return
            }
        }
        //No DFU found at this point, disconnect and report
        self.deviceNotSupported()
    }

}
