//
//  GlucoseMeasurementView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 11/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - GlucoseMeasurementView

struct GlucoseMeasurementView: View {
    
    // MARK: Private Properties
    
    private let sequenceNumber: Int
    private let itemValue: String
    private let sensor: String?
    private let location: String?
    private let status: String?
    private let dateString: String
    
    // MARK: init
    
    init(sequenceNumber: Int, itemValue: String, sensor: String? = nil,
         location: String? = nil, status: String? = nil, dateString: String) {
        self.sequenceNumber = sequenceNumber
        self.itemValue = itemValue
        self.sensor = sensor
        self.location = location
        self.status = status
        self.dateString = dateString
    }
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                BadgeView(name: "# \(sequenceNumber)")
                
                Text(itemValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 4.0) {
                if let sensor {
                    Label(sensor, systemImage: "tag")
                }
                
                if let location {
                    Label(location, systemImage: "mappin")
                }
                
                if let status {
                    Label(status, systemImage: "info.bubble")
                }
            }
            .font(.caption)
            .labelStyle(.customSpacing(8.0))
            .foregroundStyle(.secondary)
            .padding(.leading, 36)
            
            HStack {
                DotView(.nordicRed)
                
                Text(dateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
    }
}


// MARK: - CustomLabelSpacing

fileprivate extension LabelStyle where Self == CustomLabelSpacing {
    
    static func customSpacing(_ spacing: Double) -> CustomLabelSpacing {
        return CustomLabelSpacing(spacing)
    }
}

fileprivate struct CustomLabelSpacing: LabelStyle {
    
    // MARK: Private Properties
    
    private let spacing: Double
    
    // MARK: init
    
    init(_ spacing: Double) {
        self.spacing = spacing
    }
    
    // MARK: body
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            
            configuration.title
        }
    }
}
