//
//  ContentView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 07/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hudState: HUDState
    
    var body: some View {
        ZStack {
            ConnectedDevicesScreen()
            /*
            NavigationSplitView {
                ConnectedDevicesScreen()
                    .navigationTitle("Connected Devices")
            } detail: {
                NoContentView(
                    title: "Device is not selected",
                    systemImage: "filemenu.and.selection",
                    description: "Select any device from the list of connected devices")
            }
             */
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
