//
//  DeviceDetailsView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 18/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock

struct DeviceDetailsView: View {
    @ObservedObject var peripheralHandler: DeviceDetailsViewModel
    
    var body: some View {
        ServiceView(services: peripheralHandler.serviceHandlers)
            .navigationTitle(peripheralHandler.deviceName)
    }
}

struct DeviceDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDetailsView(peripheralHandler: DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(blinky)))
    }
}
