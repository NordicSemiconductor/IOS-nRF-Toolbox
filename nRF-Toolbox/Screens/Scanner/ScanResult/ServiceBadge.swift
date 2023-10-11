//
//  ServiceBadge.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

struct ServiceBadge: View {
    let image: Image?
    let name: String
    let color: Color
    
    init(image: Image?, name: String, color: Color) {
        self.image = image
        self.name = name
        self.color = color
    }
    
    init(name: String) {
        self.image = nil
        self.name = name
        self.color = .secondary
    }
    
    init(service: Service) {
        self.image = service.systemImage ?? Image(systemName: "")
        self.name = service.name
        self.color = service.color ?? .secondary
    }
    
    var body: some View {
        HStack {
            image?
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 12, maxHeight: 12)
                .foregroundColor(color)
            Text(name)
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
        .background(.blue.opacity(0.15))
        .cornerRadius(6)
    }
}

struct ServiceBadge_Previews: PreviewProvider {
    static var previews: some View {
        List {
            VStack(alignment: .leading) {
                Text("Some Device")
                HStack {
                    ServiceBadge(
                        image: Image(systemName: "scalemass.fill"),
                        name: "Weight Scale",
                        color: .green
                    )
                    
                    ServiceBadge(
                        image: Image(systemName: "figure.outdoor.cycle"),
                        name: "Cycle Sensor",
                        color: .yellow
                    )
                    
                    ServiceBadge(
                        image: nil,
                        name: "Cycle Sensor",
                        color: .yellow
                    )
                }
            }
        }
    }
}
