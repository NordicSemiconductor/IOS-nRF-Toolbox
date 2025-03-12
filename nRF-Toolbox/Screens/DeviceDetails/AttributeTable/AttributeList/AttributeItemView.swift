//
//  AttributeItemView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

// MARK: - AttributeItemView

struct AttributeItemView: View {
    
    // MARK: Private Properties
    
    private let attribute: Attribute
    
    // MARK: init
    
    init(_ attribute: Attribute) {
        self.attribute = attribute
    }
    
    // MARK: view
    
    var body: some View {
        HStack {
            paddingIndicators(attribute.level)
            
            VStack(alignment: .leading) {
                Text(attribute.name)
                    .font(.headline)
                Text(attribute.uuidString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func paddingIndicators(_ count: UInt) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Rectangle()
                    .fill(.cyan.opacity(0.8 - Double(i) * 0.2))
                    .frame(width: 6)
            }
            Spacer()
        }
        .frame(width: 40)
    }
}
