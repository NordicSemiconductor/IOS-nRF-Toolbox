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

extension AttributeTableScreen {
    @MainActor 
    class ViewModel: ObservableObject {
        let env = Environment()
        
        let peripheral: Peripheral
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
        }
        
        func readAttributeTable() async {
            do {
                env.attributeTable = try await readAttributes()
            } catch {
                env.criticalError = .unableBuildAttributeTable
            }
        }
    }
    
    @MainActor
    class MockViewModel: ViewModel {
        static let shared = MockViewModel(peripheral: .preview)
        
        override func readAttributeTable() async {
            
        }
    }
}

private typealias ViewModel = AttributeTableScreen.ViewModel

private extension ViewModel {
    func readAttributes() async throws -> [Attribute] {
        var at = AttributeTable()
        
        let services = try await peripheral.discoverServices(serviceUUIDs: nil).timeout(10, scheduler: DispatchQueue.main).value
        for s in services {
            at.addService(s)
            
            let characteristics = try await peripheral.discoverCharacteristics(nil, for: s).timeout(10, scheduler: DispatchQueue.main).value
            for c in characteristics {
                
                at.addCharacteristic(c)
                
                let descriptors = try await peripheral.discoverDescriptors(for: c).timeout(10, scheduler: DispatchQueue.main).value
                for d in descriptors {
                    at.addDescriptor(d)
                }
            }
        }
        
        return at.attributeList
    }
}

extension AttributeTableScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var attributeTable: [Attribute]?
        @Published fileprivate (set) var criticalError: CriticalError?
        
        init(attributeTable: [Attribute]? = nil, criticalError: CriticalError? = nil) {
            self.attributeTable = attributeTable
            self.criticalError = criticalError
        }
    }
}

extension AttributeTableScreen.ViewModel.Environment {
    enum CriticalError: Error {
        case unableBuildAttributeTable
    }
}
