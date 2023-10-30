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
        if let attributeTable = environment.attributeTable {
           AttributeList(attributes: attributeTable)
        } else {
            placeholder
        }
    }
    
    @ViewBuilder
    private var placeholder: some View {
        NoContentView(configuration:
                .init(text: "Discovering . . .", systemName: "table")
        )
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
