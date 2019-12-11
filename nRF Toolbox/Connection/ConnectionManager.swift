//
//  ConnectionManager.swift
//  Scanner
//
//  Created by Nick Kibysh on 01/12/2019.
//  Copyright © 2019 Nick Kibysh. All rights reserved.
//

import CoreBluetooth
import os.log

// com.NordicSemi.IOS-nRF-Scanner

protocol ConnectionManagerDelegate: class {
    func statusChanges(_ status: ConnectionManager.Status)
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

open class ConnectionManager: NSObject {
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
    
    private (set) var status: Status = .uninitialized {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.statusChanges(self.status)
            }
        }
    }
    
    private var centralManager: CBCentralManager!
    private let bgQueue = DispatchQueue(label: "no.nordicsemi.nRF-Toolbox.ConnectionManager", qos: .utility)
    private lazy var dispatchSource: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(queue: self.bgQueue)
        t.setEventHandler {
            let oldPeripherals = self.peripherals
            let oldSet: Set<Peripheral> = Set(oldPeripherals)
            self.tmpPeripherals.subtract(oldSet)
            let p = Array(self.tmpPeripherals)
            
            DispatchQueue.main.sync { [weak self] in
                guard let `self` = self else { return }
                
                self.delegate?.newPeripherals(p, willBeAddedTo: oldPeripherals)
                self.peripherals += p
                self.delegate?.peripherals(p, addedTo: oldPeripherals)
            }
            
            self.tmpPeripherals.removeAll()
        }
        return t
    }()
    
    weak var delegate: ConnectionManagerDelegate? {
        didSet {
            delegate?.statusChanges(status)
        }
    }
    
    private var tmpPeripherals = Set<Peripheral>()
    private (set) var peripherals: [Peripheral] = []
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bgQueue)
    }
    
    open func startScanning(services: [CBUUID]?) {
        let uuid = CBUUID(string: "180A")
        centralManager.scanForPeripherals(withServices: [uuid], options:
            [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        dispatchSource.schedule(deadline: .now() + .seconds(1), repeating: 1)
        dispatchSource.activate()
        status = .scanning
    }
    
    open func refresh() {
        peripherals.removeAll()
        
    }
    
    open func connect(to peripheral: Peripheral) {
        self.status = .connecting(peripheral)
        self.centralManager.stopScan()
        self.centralManager.connect(peripheral.peripheral)
    }
}

extension ConnectionManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn, .resetting:
            self.status = .ready
            startScanning(services: nil)
        case .poweredOff, .unauthorized, .unknown, .unsupported:
            self.status = .notReady(central.state)
        @unknown default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "N/A"
        let p = Peripheral(peripheral: peripheral, rssi: RSSI, name: name)
        tmpPeripherals.insert(p)
    }
     
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard case .connecting(let p) = self.status else { return }
        guard p.peripheral == peripheral else { return }
        self.status = .connected(p)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard case .connecting(let p) = self.status else { return }
        guard p.peripheral == peripheral else { return }
        
        self.status = .failedToConnect(p, error)
    }
}
