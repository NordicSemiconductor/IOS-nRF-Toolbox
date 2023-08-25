//
//  DeviceItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 13/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import CoreBluetoothMock

private extension AttributeTable {
    var serviceRepresentation: [ServiceRepresentation] {
        services.compactMap { ServiceRepresentation(identifier: $0.id) }
    }
}

struct DeviceItem: View {
    @ObservedObject var peripheral: DeviceDetailsViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(peripheral.cbPeripheral.name.deviceName)
                .font(.headline)
            HStack {
                ForEach(peripheral.serviceHandlers) { service in
                    ServiceBadge(serviceRepresentatino: ServiceRepresentation(identifier: service.service.uuid.uuidString)!)
                }
            }
        }
    }
}

struct DeviceItem_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DeviceItem(peripheral: DeviceDetailsViewModel(cbPeripheral: CBMPeripheralPreview(hrm), requestReconnect: { _ in }))
        }
    }
}

