//
//  DeviceInformationView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 06/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - DeviceInformationView

struct DeviceInformationView: View {
    
    // MARK: Private Properties
    
    private let deviceInformation: DeviceInformation

    // MARK: init
    
    init(_ deviceInformation: DeviceInformation) {
        self.deviceInformation = deviceInformation
    }
    
    // MARK: view
    
    var body: some View {
        ForEach(deviceInformation.characteristics) { characteristic in
            DeviceInformationCharacteristicView(characteristic)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - DeviceInformationCharacteristicView

struct DeviceInformationCharacteristicView: View {
    
    // MARK: Properties
    
    private let characteristic: DeviceInformation.Characteristic
    
    // MARK: init
    
    init(_ characteristic: DeviceInformation.Characteristic) {
        self.characteristic = characteristic
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            Text(characteristic.name)
            
            Spacer()
            
            Text(characteristic.value)
                .foregroundColor(.secondary)
        }
    }
}
