/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import CoreBluetooth
import os.log

protocol PeripheralScannerDelegate: AnyObject {
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
    var serviceFilterEnabled = true {
        didSet {
            refresh()
        }
    }
    
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
        rescan()
        dispatchSource.schedule(deadline: .now() + .seconds(1), repeating: 1)
        dispatchSource.activate()
        status = .scanning
    }
    
    open func refresh() {
        stopScanning()
        peripherals.removeAll()
        tmpPeripherals.removeAll()
        rescan()
    }
    
    open func stopScanning() {
        centralManager.stopScan()
        status = .ready
    }
    
    open func connect(to peripheral: Peripheral) {
        stopScanning()
        status = .connecting(peripheral)
    }
    
    private func rescan() {
        let services = serviceFilterEnabled ? scanServices : nil
        centralManager.scanForPeripherals(withServices: services, options:
            [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        status = .scanning
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
