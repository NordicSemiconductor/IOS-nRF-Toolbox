//
//  ScanResultItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct ScanResultItem: View {
    let name: String?
    let rssi: Int
    let services: [ServiceRepresentation]
    let otherServices: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                RSSIView(rssi: BluetoothRSSI(rawValue: rssi))
                Text(name ?? "n/a")
                    .foregroundColor(name == nil ? .secondary : .primary)
            }
            
            servicesView
        }
    }
    
    @ViewBuilder
    var servicesView: some View {
        switch (services.count, otherServices) {
        case (let s, 0) where s > 0:
            ForEach(services, id: \.name) {
                ServiceBadge(image: $0.icon, name: $0.name, color: $0.color)
            }
        case (0, let o) where o > 0:
            ServiceBadge(name: "\(otherServices) services")
        case (let s, let o) where s > 0 && o > 0:
            ForEach(services, id: \.name) {
                ServiceBadge(image: $0.icon, name: $0.name, color: $0.color)
            }
            ServiceBadge(name: "+\(otherServices) services")
        default: EmptyView()
        }
    }
}

#if DEBUG
import iOS_Bluetooth_Numbers_Database

struct ScanResultItem_Previews: PreviewProvider {
    typealias S = iOS_Bluetooth_Numbers_Database.Service
    
    private struct Mock {
        let name: String
        let rssi: Int
        let services: [ServiceRepresentation]
        
        static let mocks: [Mock] = [
            Mock(name: "Blinki", rssi: -50, services: [
                ServiceRepresentation(
                    identifier: S.HeartRate.heartRate.identifier
                ),
                ServiceRepresentation(
                    identifier: S.WeightScale.weightScale.identifier
                ),
            ].compactMap {$0} ),
            Mock(name: "Heart Rate", rssi: -80, services: []),
            Mock(name: "Running Sensor", rssi: -90, services: []),
            Mock(name: "Body Weight", rssi: -90, services: []),
            Mock(name: "Gluecose Sensor", rssi: -100, services: []),
            Mock(name: "Continious Gluecose Sensor", rssi: -110, services: []),
        ]
    }
    
    static var previews: some View {
        List(Mock.mocks, id: \.name) {
            ScanResultItem(name: $0.name, rssi: $0.rssi, services: [], otherServices: 1)
        }
    }
}
#endif
