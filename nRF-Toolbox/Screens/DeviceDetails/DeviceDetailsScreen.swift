//
//  DeviceDetailsScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct DeviceDetailsScreen: View {
    var body: some View {
        DeviceDetailsView()
    }
}

struct DeviceDetailsView: View {
    var body: some View {
        Text("Device Details")
    }
}

#Preview {
    NavigationStack {
        DeviceDetailsView()
    }
}
