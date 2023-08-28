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
    let discoverTableAction: () -> ()
    
    var body: some View {
        if attributeTable.services.isEmpty {
            emptyView
        } else {
            List {
                attributeTableView
            }
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        ContentUnavailableView(configuration: ContentUnavailableConfiguration(
            text: "Attribute Table is not discovered",
            secondaryText: "Would you like to discover all available services, characteristics and descriptors",
            systemName: "list.bullet.rectangle"
        ),
        actions: {
            Button("Discover", action: self.discoverTableAction)
                .buttonStyle(NordicPrimary())
        })
    }
    
    @ViewBuilder
    private var attributeTableView: some View {
        ForEach(attributeTable.services) { service in
            AttributeTableItemView(type: .service(service))
            ForEach(service.characteristics) { characteristic in
                AttributeTableItemView(type: .characteristic(characteristic))
                
                ForEach(characteristic.descriptors) { descriptor in
                    AttributeTableItemView(type: .descriptor(descriptor))
                }
            }
        }
    }
}

struct AttributeTableView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AttributeTableView(attributeTable: AttributeTable(), discoverTableAction: {})
            
            AttributeTableView(attributeTable: AttributeTable.preview, discoverTableAction: {})
        }
    }
}
