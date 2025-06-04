//
//  AttributeTableScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - AttributeTableScreen

struct AttributeTableScreen: View {

    // MARK: Private Properties
    
    private let attributeTable: AttributeTable?
    
    // MARK: init
    
    init(_ attributeTable: AttributeTable?) {
        self.attributeTable = attributeTable
    }

    // MARK: view
    
    var body: some View {
        AttributeTableView(attributeTable)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Attribute Table")
    }
}

// MARK: - AttributeTableView

struct AttributeTableView: View {
    
    // MARK: Private Properties
    
    private let attributeTable: AttributeTable?
    
    // MARK: init
    
    init(_ attributeTable: AttributeTable?) {
        self.attributeTable = attributeTable
    }
    
    // MARK: view
    
    var body: some View {
        List {
            if let attributeTable, attributeTable.services.hasItems {
                AttributeList(attributeTable)
            } else {
                NoContentView(title: "Attributes not found", systemImage: "table")
            }
            
            // "Fix" for DisclosureGroup not expanding for all Service(s). Which is, the last item will
            // fade in/out instead of expanding. So we need to add a static element at the bottom.
            Section("Troubleshooting") {
                Label("If you can't find your service, turn off and on Bluetooth from Settings (not Control Center).",
                      systemImage: "exclamationmark.magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Attribute

protocol Attribute  {
    
    var level: UInt { get }
    var name: String { get }
    var uuidString: String { get }
    var id: String { get }
    var children: [Attribute] { get }
}
