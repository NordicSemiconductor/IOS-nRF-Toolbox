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
        if let attributeTable {
            AttributeList(attributeTable)
        } else {
            NoContentView(title: "Discovering . . .", systemImage: "table")
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
