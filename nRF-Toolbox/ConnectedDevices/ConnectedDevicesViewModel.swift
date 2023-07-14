//
//  ConnectedDevicesViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Combine

extension ConnectedDevicesView {
    struct Device: Identifiable {
        let name: String
        let id: UUID
    }
    
    @MainActor
    class ViewModel: ObservableObject {
        private var cancelables = Set<AnyCancellable>()
        
        @Published var devices: [PeripheralStructure] = []
        @Published var handlers: [PeripheralHelper] = []
        
        let bluetoothManager: CentralManagerHelper
        
        init(bluetoothManager: CentralManagerHelper = .shared) {
            self.bluetoothManager = bluetoothManager
            
            bluetoothManager.$peripheralManagers
                .sink { _ in
                    
                } receiveValue: { v in
                    self.devices = v.map(\.peripheralRepresentation)
                }
                .store(in: &cancelables)
            
            bluetoothManager.$peripheralManagers
                .assign(to: &$handlers)

            $handlers.map {
                print(#function)
                $0.forEach { d in print(d.serviceCount()) }
                self.objectWillChange.send()
                return $0.map(\.peripheralRepresentation)
            }
            .assign(to: &$devices)
        }
        
    }
    
}

extension ConnectedDevicesView.ViewModel {
    private func setupBluetoothManager() {
        Task {
        }
    }
}
