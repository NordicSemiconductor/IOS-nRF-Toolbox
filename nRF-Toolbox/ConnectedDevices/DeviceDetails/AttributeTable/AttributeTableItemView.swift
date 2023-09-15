//
//  AttributeTableItemView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 21/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct AttributeTableItemView: View {
    enum AttributeType: Identifiable {
        case service(AttributeTable.Service)
        case characteristic(AttributeTable.Service.Characteristic)
        case descriptor(AttributeTable.Service.Characteristic.Descriptor)
        
        var item: NamedItem & StringIdentifiable {
            switch self {
            case .characteristic(let i): return i
            case .descriptor(let i): return i
            case .service(let i): return i
            }
        }
        
        var id: String {
            switch self {
            case .service(let s): return s.id
            case .characteristic(let c): return c.id
            case .descriptor(let d): return d.id
            }
        }
    }
    
    let type: AttributeType
    
    var body: some View {
        HStack {
            paddingIndicator()
                .frame(width: 40)
            infoView(item: type.item)
        }
    }
    
    @ViewBuilder
    private func infoView(item: StringIdentifiable & NamedItem) -> some View {
        VStack(alignment: .leading) {
            Text(item.name ?? "unnamed")
                .font(.headline)
                .foregroundColor(item.name != nil ? .primary : .secondary)
            HStack {
                Text("Type: ")
                Text(item.identifier)
                    .foregroundColor(.secondary)
            }
            (item as? AttributeTable.Service.Characteristic)
                .map { ch in
                    HStack {
                        Text("Properties: ")
                        Text(ch.prepertiesDescription)
                            .foregroundColor(.secondary)
                    }
                }
        }
    }
    
    @ViewBuilder
    private func paddingIndicator() -> some View {
        switch type {
        case .service(_):
            paddingIndicators(1)
        case .characteristic(_):
            paddingIndicators(2)
        case .descriptor(_):
            paddingIndicators(3)
        }
    }
    
    @ViewBuilder
    private func paddingIndicators(_ count: Int) -> some View {
        HStack {
            ForEach(0..<count, id: \.self) { i in
                Rectangle()
                    .fill(.cyan.opacity(0.8 - Double(i) * 0.2))
                    .frame(width: 6)
            }
            Spacer()
        }
    }
}

struct AttributeTableItemView_Previews: PreviewProvider {
    static let at = AttributeTable.preview
    
    static var previews: some View {
        List {
            AttributeTableItemView(type: .service(at.services[2]))
            AttributeTableItemView(type: .characteristic(at.services[2].characteristics[0]))
            AttributeTableItemView(type: .descriptor(at.services[2].characteristics[0].descriptors[0]))
        }
    }
}
