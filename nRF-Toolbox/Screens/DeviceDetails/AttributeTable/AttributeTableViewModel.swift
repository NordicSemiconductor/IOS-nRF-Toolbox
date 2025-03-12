//
//  AttributeTableViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI
import iOS_Bluetooth_Numbers_Database
import iOS_BLE_Library_Mock
import iOS_Common_Libraries

// MARK: - AttributeTableViewModel

extension AttributeTableScreen {
    
    @MainActor
    class AttributeTableViewModel: ObservableObject {
        
        let env = Environment()
        
        private let peripheral: Peripheral
        private let log = NordicLog(category: "AttributeTable.VM", subsystem: "com.nordicsemi.nrf-toolbox")
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
        
        func readAttributeTable() async {
            do {
                env.attributeTable = try await attributeTable()
            } catch {
                env.criticalError = .unableBuildAttributeTable
            }
        }
    }
    
    #if DEBUG
    @MainActor
    class MockViewModel: AttributeTableViewModel {
        static let shared = MockViewModel(peripheral: .preview)
        
        override func readAttributeTable() async {
            
        }
    }
    #endif
}

private typealias ViewModel = AttributeTableScreen.AttributeTableViewModel

// MARK: - ViewModel Extension

private extension ViewModel {
    
    func attributeTable() async throws -> AttributeTable {
        var table = AttributeTable()
        
        let services = try await peripheral.discoverServices(serviceUUIDs: nil).timeout(10, scheduler: DispatchQueue.main).firstValue
        for service in services {
            table.addService(service)
            
            let characteristics = try await peripheral.discoverCharacteristics(nil, for: service).timeout(10, scheduler: DispatchQueue.main).firstValue
            for characteristic in characteristics {
                table.addCharacteristic(characteristic, to: service)
                
                let descriptors = try await peripheral.discoverDescriptors(for: characteristic).timeout(10, scheduler: DispatchQueue.main).firstValue
                for descriptor in descriptors {
                    table.addDescriptor(descriptor, to: characteristic, in: service)
                }
            }
        }
        
        return table
    }
    
    func attributeList() async throws -> [Attribute] {
        let table = try await attributeTable()
        return table.attributeList
    }
}

// MARK: - Attribute

protocol Attribute  {
    var level: UInt { get }
    var name: String { get }
    var uuidString: String { get }
    var id: String { get }
}

// MARK: - Environment

extension AttributeTableScreen.AttributeTableViewModel {
    
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate(set) var attributeTable: AttributeTable?
        @Published fileprivate(set) var criticalError: CriticalError?
        
        private let log = NordicLog(category: "AttributeTable.Env", subsystem: "com.nordicsemi.nrf-toolbox")
        
        init(attributeTable: AttributeTable? = nil, criticalError: CriticalError? = nil) {
            self.attributeTable = attributeTable
            self.criticalError = criticalError
            
            log.debug(#function)
        }
        
        deinit {
            log.debug(#function)
        }
    }
}

// MARK: - CriticalError

extension AttributeTableScreen.AttributeTableViewModel.Environment {
    
    enum CriticalError: Error {
        case unableBuildAttributeTable
        
        var localizedDescription: String {
            switch self {
            case .unableBuildAttributeTable: "Unable to build attribute table." 
            }
        }
    }
}
