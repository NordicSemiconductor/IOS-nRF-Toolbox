//
//  CGMSRecordList.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 8/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - CGMSRecordList

struct CGMSRecordList: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: CGMSViewModel
    
    // MARK: view
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.records, id: \.sequenceNumber) { value in
                    VStack(alignment: .leading) {
                        HStack {
                            ServiceBadge(name: "# \(value.sequenceNumber)")
                            
                            Text(value.description)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Text(value.toStringDate())
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("")
            } footer: {
                Text("\(viewModel.records.count) Records")
                    .foregroundStyle(Color.nordicMiddleGrey)
                    .font(.caption)
            }
        }
        .navigationTitle("Glucose Records")
        .toolbar {
            Button("", systemImage: "arrow.counterclockwise") {
                Task {
                    await viewModel.requestAllRecords()
                }
            }
        }
    }
}
