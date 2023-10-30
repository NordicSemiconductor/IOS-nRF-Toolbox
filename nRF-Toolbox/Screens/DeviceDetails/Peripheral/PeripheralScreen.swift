//
//  PeripheralScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 30/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = PeripheralScreen.ViewModel.Environment

struct PeripheralScreen: View {

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        PeripheralView()
            .environmentObject(viewModel.env)
    }
}

struct PeripheralView: View {
    @EnvironmentObject private var environment: Env

    var body: some View {
        List {
            Section {
                NavigationLink {
                    // TODO: Attribuet Table Screen
                    Text("Attribute Table")
                } label: {
                    Text("Attribute Table")
                }
            }
            
            SignalChartView()
                .environmentObject(environment.signalChartViewModel.environment)
            
            Section {
                Button("Disconnect") {
                    
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TabView {
            PeripheralView()
                .environmentObject(Env())
                .tabItem { Label("Device", systemImage: "apple.terminal") }
        }
        .navigationTitle("Device Info")
    }
}
