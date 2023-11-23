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

extension AttributeTableScreen {
    @MainActor 
    class AttributeTableViewModel: ObservableObject {
        let env = Environment()
        
        let peripheral: Peripheral
        
        private let l = L(category: "AttributeTable.VM")
        
        init(peripheral: Peripheral) {
            self.peripheral = peripheral
            
            l.construct()
        }
        
        deinit {
            l.descruct()
        }
        
        func readAttributeTable() async {
            do {
                env.attributeTable = try await readAttributes()
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

private extension ViewModel {
    func readAttributes() async throws -> [Attribute] {
        return []
        /*
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
         */
    }
}

extension AttributeTableScreen.AttributeTableViewModel {
    @MainActor
    class Environment: ObservableObject {
        @Published fileprivate (set) var attributeTable: [Attribute]?
        @Published fileprivate (set) var criticalError: CriticalError?
        
        private let l = L(category: "AttributeTable.Env")
        
        init(attributeTable: [Attribute]? = nil, criticalError: CriticalError? = nil) {
            self.attributeTable = attributeTable
            self.criticalError = criticalError
            
            l.construct()
        }
        
        deinit {
            l.descruct()
        }
    }
}

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
