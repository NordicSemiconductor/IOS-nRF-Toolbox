//
//  NordicEmptyView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - NordicEmptyView

struct NordicEmptyView: View {
    
    // MARK: view
    
    var body: some View {
        AppIconView()
            .grayscale(1.0)
            .frame(width: 100, height: 100)
            .cornerRadius(8.0)
            .centered()
            .background(Color.secondarySystemBackground)
    }
}
