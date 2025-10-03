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
    private let measurement: Measurement<UnitConcentrationMass>?
    private let sensor: String?
    private let location: String?
    private let status: String?
    private let dateString: String
    
    // MARK: init
    
    init(sequenceNumber: Int, measurement: Measurement<UnitConcentrationMass>?,
         sensor: String? = nil, location: String? = nil, status: String? = nil,
         dateString: String) {
        self.sequenceNumber = sequenceNumber
        self.measurement = measurement
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
                
                if let measurement {
                    Text(String(format: "%.2f \(measurement.unit.symbol)", measurement.value))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            VStack(alignment: .leading, spacing: 4.0) {
                if let sensor {
                    Label(sensor, systemImage: "tag")
                }
                
                if let location {
                    Label(location, systemImage: "figure.dance")
                }
                
                if let status {
                    Label(status, systemImage: "info.bubble")
                }
            }
            .font(.caption)
            .labelStyle(.fixedIconSize(CGSize(asSquare: 12.0)))
            .foregroundStyle(.secondary)
            .padding(.leading, 8.0)
            .padding(.top, 4.0)
            
            HStack {
                DotView(.nordicRed)
                
                Text(dateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 10.0)
        }
    }
}


// MARK: - FixedIconSize

extension LabelStyle where Self == FixedIconSize {
    
    static func fixedIconSize(_ iconSize: CGSize) -> FixedIconSize {
        return FixedIconSize(iconSize)
    }
}

struct FixedIconSize: LabelStyle {
    
    // MARK: Private Properties
    
    private let iconSize: CGSize
    
    // MARK: init
    
    init(_ iconSize: CGSize) {
        self.iconSize = iconSize
    }
    
    // MARK: body
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            configuration.icon
                .frame(size: iconSize)
            
            configuration.title
        }
    }
}
