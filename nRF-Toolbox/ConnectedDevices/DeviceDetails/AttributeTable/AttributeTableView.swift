//
//  AttributeTableView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 20/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

private extension AttributeTable {
    var items: [AttributeTableItemView.AttributeType] {
        var itms: [AttributeTableItemView.AttributeType] = []
        for s in services {
            itms.append(.service(s))
            for c in s.characteristics {
                itms.append(.characteristic(c))
                for d in c.descriptors {
                    itms.append(.descriptor(d))
                }
            }
        }
        return itms
    }
}

struct AttributeTableView: View {
    let attributeTable: AttributeTable
    let discoverTableAction: () -> ()
    
    var body: some View {
        if attributeTable.services.isEmpty {
            emptyView
        } else {
            List {
                ForEach(attributeTable.items) {
                    AttributeTableItemView(type: $0)
                }
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
}

struct AttributeTableView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AttributeTableView(attributeTable: AttributeTable(), discoverTableAction: {})
            
            AttributeTableView(attributeTable: AttributeTable.preview, discoverTableAction: {})
        }
    }
}
