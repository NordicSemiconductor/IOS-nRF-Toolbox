//
//  DeviceItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 13/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct DeviceItem: View {
    let name: String
    let services: [ServiceRepresentation]
    
    var body: some View {
        VStack {
            Text(name)
                .font(.headline)
            HStack {
                ForEach(services, id: \.name) { service in
                    ServiceBadge(serviceRepresentatino: service)
                }
            }
        }
        
        
    }
}

struct DeviceItem_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DeviceItem(name: "Device 1", services: [
                ServiceRepresentation(identifier: "180D")
            ].compactMap { $0 })
        }
    }
}
