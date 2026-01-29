//
//  UARTView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTView

struct UARTView: View {
    
    // MARK: EnvironmentObject
    
    @Environment(UARTViewModel.self) private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
        Text("Latest Messages")
            .font(.title2.bold())
        
        UARTMessagesPreview(viewModel.messages.suffix(4))
        
        UARTSendMessageView()
            .fixedListRowSeparatorPadding()
        
        NavigationLink("All Messages (\(viewModel.messages.count))") {
            UARTMessagesList()
                .environment(viewModel)
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
