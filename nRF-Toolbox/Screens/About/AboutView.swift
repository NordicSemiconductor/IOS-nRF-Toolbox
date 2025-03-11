//
//  AboutView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 11/3/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - AboutView

struct AboutView: View {
    
    // MARK: Environment
    
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: view
    
    var body: some View {
        List {
            Section("") {
                AppIconView()
                    .frame(width: 100, height: 100)
                    .centered()
                    .padding(.top)
                
                Text("nRF Toolbox")
                    .font(.title)
                    .centered()
                
                Text("Version: \(AppInfo.readVersion())")
                    .font(.caption)
                    .centered()
            }
            .listRowSeparator(.hidden)
            
            Section("Description") {
                Text("""
                nRF Toolbox is a multi-purpose container app providing access to multiple Bluetooh Low Energy profiles:
                
                • Cycling Speed and Cadence
                • Running Speed and Cadence
                • Heart Rate Monitor
                • Blood Pressure Monitor
                • Health Thermometer Monitor
                • Glucose Monitor
                • Continuous Glucose Monitor
                • Proximity Monitor
                • Battery Level
                • Throughput
                """)
            }
            .listRowSeparator(.hidden)
             
            Section("Requirements") {
                Label("Supported firmware flashed on device", systemImage: "cpu")
                
                Label("Device powered ON", systemImage: "bolt.fill")
                
                Label("Device in advertising range", systemImage: "wave.3.up")
            }
            .listRowSeparator(.hidden)
            
            Button("Back to Toolbox") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.bottom)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .setAccent(.nordicBlue)
    }
}
