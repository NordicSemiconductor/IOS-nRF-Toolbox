//
//  RootNavigationViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI

extension RootNavigationView {
    enum MenuCategory: String, CaseIterable, Identifiable {
        case scanner = "Scanner"
        case hrm = "HRM"
        case about = "About"
        
        var id: String {
            self.rawValue
        }
    }
}

@MainActor
class RootNavigationViewModel: ObservableObject {
    @Published var selectedCategory: RootNavigationView.MenuCategory?
    @Published var selectedDevice: ConnectedDevicesViewModel.Device.ID? 
    
    static let shared = RootNavigationViewModel()
}

