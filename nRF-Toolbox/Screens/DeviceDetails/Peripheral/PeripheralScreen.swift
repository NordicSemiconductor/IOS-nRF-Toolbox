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
    @State private var disconnectAlertShow = false
    @State private var showAttributeTable = false

    var body: some View {
        List {
            Section {
                Button("Show Attribute Table") {
                    showAttributeTable = true
                }
                .sheet(isPresented: $showAttributeTable) {
                    NavigationStack {
                        AttributeTableScreen(viewModel: environment.attributeTableViewModel)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        showAttributeTable = false
                                    }
                                }
                            }
                    }
                }
            }
            
            SignalChartView()
                .environmentObject(environment.signalChartViewModel.environment)
            
            Section {
                Button("Disconnect") {
                    disconnectAlertShow = true
                }
                .foregroundStyle(.red)
                .alert("Disconnect", isPresented: $disconnectAlertShow) {
                    Button("Yes") {
                        // TODO: Cancel Connection
                    }
                    Button("No") { }
                } message: {
                    Text("Are you sure you want to cancel peripheral connectior?")
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
