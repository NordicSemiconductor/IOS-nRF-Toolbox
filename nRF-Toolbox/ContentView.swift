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
    @EnvironmentObject var hudState: HUDState
    
    var body: some View {
        ZStack {
            NavigationSplitView {
                ConnectedDevicesScreen()
                    .navigationTitle("Connected Devices")
            } detail: {
                ContentUnavailableView(
                    configuration: ContentUnavailableConfiguration(
                        text: "Device is not selected",
                        secondaryText: "Select any device from the list of connected devices",
                        systemName: "filemenu.and.selection"
                    ))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
