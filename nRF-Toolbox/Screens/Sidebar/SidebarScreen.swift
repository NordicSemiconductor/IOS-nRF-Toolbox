//
//  SidebarScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 14/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var rootViewModel: RootNavigationViewModel
    
    var body: some View {
        List(selection: $rootViewModel.selectedCategory) {
            Section("Devices") {
                Text("Connected Devices")
                    .tag(RootNavigationView.MenuCategory.devices.id)
            }
            Section("Other") {
                Text("About")
                    .tag(RootNavigationView.MenuCategory.about.id)
                    .disabled(true)
            }
        }
        .navigationTitle("nRF Toolbox")
    }
}

#Preview {
    SidebarView()
}
