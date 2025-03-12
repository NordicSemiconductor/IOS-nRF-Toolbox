//
//  AttributeTableScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = AttributeTableScreen.AttributeTableViewModel.Environment

// MARK: - AttributeTableScreen

struct AttributeTableScreen: View {

    @ObservedObject var viewModel: AttributeTableViewModel

    // MARK: view
    
    var body: some View {
        AttributeTableView()
            .environmentObject(viewModel.env)
            .task {
                await viewModel.readAttributeTable()
            }
            .navigationTitle("Attribute Table")
    }
}

// MARK: - AttributeTableView

struct AttributeTableView: View {
    
    // MARK: Environment
    
    @EnvironmentObject private var environment: Env

    // MARK: view
    
    var body: some View {
        if let criticalError = environment.criticalError {
            NoContentView(title: "Error", systemImage: "exclamationmark.triangle", description: criticalError.localizedDescription, style: .error)
        } else if let attributeTable = environment.attributeTable {
           AttributeList(attributes: attributeTable)
        } else {
            placeholder
        }
    }
    
    @ViewBuilder
    private var placeholder: some View {
        NoContentView(title: "Discovering . . .", systemImage: "table")
    }
}
