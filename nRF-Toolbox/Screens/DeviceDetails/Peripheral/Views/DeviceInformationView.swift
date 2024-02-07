//
//  DeviceInformationView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 06/02/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct DeviceInformationView: View {
    let deviceInformation: DeviceInformation

    var body: some View {
        ForEach(deviceInformation.characteristics) { characteristic in
            deviceInformationCharacteristicView(characteristic: characteristic)
        }
        .listStyle(GroupedListStyle())
    }

    @ViewBuilder
    private func deviceInformationCharacteristicView(characteristic: DeviceInformation.Characteristic) -> some View {
        HStack {
            Text(characteristic.name)
            Spacer()
            Text(characteristic.value)
                .foregroundColor(.secondary)
        }
    }
}



#Preview {
    DeviceInformationView(deviceInformation: DeviceInformation(
        manufacturerName: "Nordic Semiconductor",
        modelNumber: "nRF52840",
        serialNumber: "123456",
        hardwareRevision: "1.0",
        firmwareRevision: "1.0",
        softwareRevision: "1.0",
        systemID: "123456",
        ieee11073: "123456"
    ))
}
