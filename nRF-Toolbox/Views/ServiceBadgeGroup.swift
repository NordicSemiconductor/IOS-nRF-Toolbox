//
//  ServiceBadgeGroup.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

struct ServiceBadgeGroup: View {
    let services: [Service]
    
    init(_ services: Set<Service>) {
        self.services = services.map({ $0 }).sorted(by: { a, b in
            a.name < b.name
        })
    }
    
    var body: some View {
        HStack {
            if services.isEmpty {
                EmptyView()
            } else {
                ForEach(services.filter({ $0.isSupported })) {
                    ServiceBadge(image: $0.systemImage, name: $0.name, color: $0.color ?? .primary)
                }
                
                otherServiceBadge(count: services.reduce(0, { $0 + ($1.isSupported ? 0 : 1)  }))
            }
        }
    }
    
    @ViewBuilder
    func otherServiceBadge(count: Int) -> some View {
        if count > 0 {
            ServiceBadge(name: otherServiceString(count: count))
        } else {
            EmptyView()
        }
    }
    
    private func otherServiceString(count: Int) -> String {
        let prefixSymbol = count == services.count ? "" : " +"
        
        let formatString : String = NSLocalizedString("service_count", comment: "")
        let resultString : String = String.localizedStringWithFormat(formatString, count)
        return prefixSymbol + resultString
    }
}

#Preview {
    List {
        ServiceBadgeGroup([.runningSpeedAndCadence])
        ServiceBadgeGroup( [.runningSpeedAndCadence, .healthThermometer])
        ServiceBadgeGroup([.weightScale])
        ServiceBadgeGroup([.weightScale, .IORuntimeMCUMGRBLESMP])
        ServiceBadgeGroup([.weightScale, .IORuntimeMCUMGRBLESMP, .heartRate, .healthThermometer])
        ServiceBadgeGroup([.weightScale, .heartRate, .healthThermometer])
        ServiceBadgeGroup([])
    }
}
