//
//  AttributeTableScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = AttributeTableScreen.ViewModel.Environment

struct AttributeTableScreen: View {

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        AttributeTableView()
            .environmentObject(viewModel.env)
            .task {
                await viewModel.readAttributeTable()
            }
            .navigationTitle("Attribute Table")
    }
}

struct AttributeTableView: View {
    @EnvironmentObject private var environment: Env

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

#Preview {
    AttributeTableView()
        .environmentObject(Env(
            attributeTable: []
        ))
}

#Preview {
    AttributeTableView()
        .environmentObject(Env(
            attributeTable: nil
        ))
}

#Preview {
    AttributeTableView()
        .environmentObject(Env(
            criticalError: .unableBuildAttributeTable
        ))
}
