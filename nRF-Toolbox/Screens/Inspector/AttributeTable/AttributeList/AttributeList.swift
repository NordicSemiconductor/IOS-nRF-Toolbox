//
//  AttributeList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 24/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database
import iOS_Common_Libraries

// MARK: - AttributeList

struct AttributeList: View {
    
    // MARK: Private
    
    private let attributeTable: AttributeTable
    
    // MARK: init
    
    init(_ attributeTable: AttributeTable) {
        self.attributeTable = attributeTable
    }
    
    // MARK: view
    
    var body: some View {
        ForEach(attributeTable.services) { service in
            if service == attributeTable.services.first {
                Section("") {
                    DisclosureAttributeItemView(service)
                }
            } else {
                Section {
                    DisclosureAttributeItemView(service)
                }
            }
        }
    }
}
