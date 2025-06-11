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
    private let item: String
    private let dateString: String
    
    // MARK: init
    
    init(sequenceNumber: Int, item: String, dateString: String) {
        self.sequenceNumber = sequenceNumber
        self.item = item
        self.dateString = dateString
    }
    
    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                BadgeView(name: "# \(sequenceNumber)")
                
                Text(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                DotView(.nordicRed)
                
                Text(dateString)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

