//
//  PeripheralScanner.swift
//  Scanner
//
//  Created by Nick Kibysh on 01/12/2019.
//  Copyright © 2019 Nick Kibysh. All rights reserved.
//

import CoreBluetooth
import os.log

protocol PeripheralScannerDelegate: class {
    func statusChanges(_ status: PeripheralScanner.Status)
    func newPeripherals(_ peripherals: [Peripheral], willBeAddedTo existing: [Peripheral])
    func peripherals(_ peripherals: [Peripheral], addedTo old: [Peripheral])
}

public struct Peripheral: Hashable, Equatable {
    let peripheral: CBPeripheral
    let rssi: NSNumber
    let name: String
    
    public static func == (lhs: Peripheral, rhs: Peripheral) -> Bool { lhs.peripheral == rhs.peripheral }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral)
    }
}

open class PeripheralScanner: NSObject {
    public enum Status {
        case uninitialized, ready, notReady(CBManagerState), scanning, connecting(Peripheral), connected(Peripheral), failedToConnect(Peripheral, Error?)
        
        var singleName: String {
            switch self {
            case .connected(let p): return "Connected to \(p.name)"
            case .uninitialized: return "Uninitialized"
            case .ready: return "Ready to scan"
            case .notReady: return "Not Ready"
            case .scanning: return "Scanning..."
            case .connecting(let p): return "Connecting to \(p.name)"
            case .failedToConnect(let p, _): return "Failed to connect to \(p.name)"
            }
        }
    }
    
    let scanServices: [CBUUID]?
    
    private (set) var status: Status = .uninitialized {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.scannerDelegate?.statusChanges(self.status)
            }
        }
    }
    
    private var centralManager: CBCentralManager!
    private let bgQueue = DispatchQueue(label: "no.nordicsemi.nRF-Toolbox.ConnectionManager", qos: .utility)
    private lazy var dispatchSource: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(queue: bgQueue)
        t.setEventHandler {
            let oldPeripherals = self.peripherals
            let oldSet: Set<Peripheral> = Set(oldPeripherals)
            self.tmpPeripherals.subtract(oldSet)
            let p = Array(self.tmpPeripherals)
            
            DispatchQueue.main.sync { [weak self] in
                guard let `self` = self else { return }
                
                self.scannerDelegate?.newPeripherals(p, willBeAddedTo: oldPeripherals)
                self.peripherals += p
                self.scannerDelegate?.peripherals(p, addedTo: oldPeripherals)
            }
            
            self.tmpPeripherals.removeAll()
        }
        return t
    }()
    
    weak var scannerDelegate: PeripheralScannerDelegate? {
        didSet {
            scannerDelegate?.statusChanges(status)
        }
    }
    
    private var tmpPeripherals = Set<Peripheral>()
    private (set) var peripherals: [Peripheral] = []
    
    init(services: [CBUUID]?) {
        scanServices = services
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bgQueue)
    }
    
    open func startScanning() {
        centralManager.scanForPeripherals(withServices: scanServices, options:
            [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        dispatchSource.schedule(deadline: .now() + .seconds(1), repeating: 1)
        dispatchSource.activate()
        status = .scanning
    }
    
    open func refresh() {
        peripherals.removeAll()
    }
    
    open func stopScanning() {
        centralManager.stopScan()
        status = .ready
    }
    
    open func connect(to peripheral: Peripheral) {
        stopScanning()
        status = .connecting(peripheral)
    }
}

extension PeripheralScanner: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn, .resetting:
            status = .ready
            startScanning()
        case .poweredOff, .unauthorized, .unknown, .unsupported:
            status = .notReady(central.state)
        @unknown default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name
            ?? "N/A"
        let p = Peripheral(peripheral: peripheral, rssi: RSSI, name: name)
        tmpPeripherals.insert(p)
    }
     
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard case .connecting(let p) = status else { return }
        guard p.peripheral == peripheral else { return }
        status = .connected(p)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard case .connecting(let p) = status else { return }
        guard p.peripheral == peripheral else { return }
        
        status = .failedToConnect(p, error)
    }
}
