//
//  ServiceBadgeGroup.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 12/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import iOS_Bluetooth_Numbers_Database

// MARK: - ServiceBadgeGroup

struct ServiceBadgeGroup: View {
    
    private let services: [Service]
    
    // MARK: init
    
    init(_ services: Set<Service>) {
        self.services = services
            .map({ $0 })
            .filter(\.isSupported)
            .sorted(by: { a, b in
                a.name < b.name
            })
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            ForEach(services) {
                BadgeView(image: $0.systemImage, name: $0.name, color: $0.color ?? .primary)
            }

            otherServicesBadge(count: services.reduce(0, { $0 + ($1.isSupported ? 0 : 1)  }))
        }
    }
    
    // MARK: otherServicesBadge(count:)
    
    @ViewBuilder
    func otherServicesBadge(count: Int) -> some View {
        if count > 0 {
            BadgeView(name: otherServiceString(count: count))
        } else {
            EmptyView()
        }
    }
    
    // MARK: otherServiceString(count:)
    
    private func otherServiceString(count: Int) -> String {
        let prefixSymbol = count == services.count ? "" : " +"
        
        let formatString: String = NSLocalizedString("service_count", comment: "")
        let resultString: String = String.localizedStringWithFormat(formatString, count)
        return prefixSymbol + resultString
    }
}
