//
//  AttributeList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 24/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

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
        if attributeTable.isEmpty {
            NoContentView(
                title: "Attributes not found",
                systemImage: "table")
        } else {
            List {
                ForEach(attributeTable.services) { service in
                    Section("") {
                        if service.characteristics.hasItems {
                            DisclosureGroup {
                                ForEach(service.characteristics) { characteristic in
                                    if characteristic.descriptors.hasItems {
                                        DisclosureGroup {
                                            ForEach(characteristic.descriptors) { descriptor in
                                                AttributeItemView(attribute: descriptor)
                                            }
                                        } label: {
                                            AttributeItemView(attribute: characteristic)
                                        }
                                        .accentColor(.nordicMiddleGrey)
                                    } else {
                                        AttributeItemView(attribute: characteristic)
                                    }
                                }
                            } label: {
                                AttributeItemView(attribute: service)
                            }
                            .accentColor(.nordicMiddleGrey)
                        } else {
                            AttributeItemView(attribute: service)
                        }
                    }
                }
            }
        }
    }
}
