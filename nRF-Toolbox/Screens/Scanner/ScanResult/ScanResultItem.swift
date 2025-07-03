//
//  ScanResultItem.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import iOS_Bluetooth_Numbers_Database

// MARK: - ScanResultItem

struct ScanResultItem: View {
    
    // MARK: Properties
    
    private let name: String?
    private let services: Set<Service>
    private let inProgress: Bool
    
    // MARK: init
    
    init(name: String?, services: Set<Service>, showProgress: Bool = false) {
        self.name = name
        self.services = services
        self.inProgress = showProgress
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(name ?? "Unnamed Device")
                        .foregroundColor(name == nil ? .secondary : .primary)
                    
                    if services.hasItems {
                        ServiceBadgeGroup(services)
                    }
                }
            } icon: {
                Image(systemName: "cpu")
                    .foregroundStyle(Color.universalAccentColor)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.trailing, 8)
            .padding(.bottom, 6)
            
            ProgressView()
                .opacity(inProgress ? 1.0 : 0.0)
        }
    }
}
