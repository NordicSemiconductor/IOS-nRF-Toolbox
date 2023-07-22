//
//  AttributeTableView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 20/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct AttributeTableView: View {
    let attributeTable: AttributeTable
    
    var body: some View {
        if attributeTable.services.isEmpty {
            emptyView
        } else {
            attributeTableView
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        ContentUnavailableView(configuration: ContentUnavailableConfiguration(
            text: "Attribute Table is not discovered",
            secondaryText: "Would you like to discover all available services, characteristics and descriptors",
            systemName: "list.bullet.rectangle",
            buttonConfiguration: ContentUnavailableConfiguration.ButtonConfiguration(title: "Discover", action: {
                
            })
        ))
    }
    
    @ViewBuilder
    private var attributeTableView: some View {
        ForEach(attributeTable.services) { service in
            Text(service.name ?? "no name")
            ForEach(service.characteristics) { characteristic in
                Text(characteristic.name ?? "no name")
                
                ForEach(characteristic.descriptors) { descriptor in
                    Text(descriptor.name ?? "no name")
                }
            }
        }
    }
}

struct AttributeTableView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AttributeTableView(attributeTable: AttributeTable())
            List {
                AttributeTableView(attributeTable: AttributeTable.preview)
            }
        }
    }
}
