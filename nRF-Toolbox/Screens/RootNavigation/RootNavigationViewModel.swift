//
//  RootNavigationViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI

// MARK: - RootNavigationViewModel

@MainActor
final class RootNavigationViewModel: ObservableObject {
    
    @Published var selectedCategory: RootNavigationView.MenuCategory?
    @Published var showAboutView: Bool = false
    
    static let shared = RootNavigationViewModel()
}

// MARK: - MenuCategory

extension RootNavigationView {
    
    enum MenuCategory: String, CaseIterable, Identifiable {
        case scanner = "Scanner"
        case device = "DeviceDetails"
        
        var id: String {
            self.rawValue
        }
    }
}
