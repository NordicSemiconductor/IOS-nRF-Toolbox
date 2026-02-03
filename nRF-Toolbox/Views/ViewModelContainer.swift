//
//  ViewModelContainer.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 03/02/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct ViewModelContainer<ViewModel, Content: View>: View {
    
    let createVM: () -> ViewModel
    @State var viewModel: ViewModel? = nil
    @ViewBuilder let content: (ViewModel) -> Content
    
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                content(viewModel)
            } else {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.task {
            if viewModel == nil {
                viewModel = createVM()
            }
        }
    }
}
