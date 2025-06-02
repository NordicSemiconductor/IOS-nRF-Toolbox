//
//  DisclosureAttributeItemView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 12/3/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - DisclosureAttributeItemView

struct DisclosureAttributeItemView: View {
    
    // MARK: Private Properties
    
    private let attribute: Attribute
    
    // MARK: init
    
    init(_ attribute: Attribute) {
        self.attribute = attribute
    }
    
    // MARK: view
    
    var body: some View {
        if attribute.children.hasItems {
            DisclosureGroup {
                ForEach(attribute.children, id: \.id) { child in
                    DisclosureAttributeItemView(child)
                        .padding(.leading, -20.0)
                }
            } label: {
                AttributeItemView(attribute)
            }
            .accentColor(.nordicMiddleGrey)
        } else {
            AttributeItemView(attribute)
        }
    }
}
