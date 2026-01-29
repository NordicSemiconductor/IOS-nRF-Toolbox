//
//  LogsToolbarItem.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 28/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct LogsToolbarItem: ToolbarContent {
    
    // MARK: Environment
    
    @Environment(RootNavigationViewModel.self) var viewModel: RootNavigationViewModel
    
    // MARK: view
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.selectedCategory = .logs(LogsTab.preview)
            } label: {
                Image(systemName: "text.magnifyingglass")
            }
        }
    }
}
