//
//  ContentView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            ConnectedDevicesView()
                .navigationTitle("Connected Devices")
        } detail: {
            Text("Device Details")
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
