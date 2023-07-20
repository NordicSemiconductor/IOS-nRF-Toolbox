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
        
        @Published var handlers: [DeviceDetailsViewModel] = []
        
        let bluetoothManager: CentralManagerHelper
        
        init(bluetoothManager: CentralManagerHelper = .shared) {
            self.bluetoothManager = bluetoothManager
            
            bluetoothManager.$peripheralManagers
                .assign(to: &$handlers)
        }
    }
}

