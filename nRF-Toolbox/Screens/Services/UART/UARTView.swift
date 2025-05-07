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
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: view
    
    var body: some View {
        Text("Latest Messages")
            .font(.title2.bold())
        
        UARTMessagesPreview(viewModel.messages.suffix(4))
        
        Text("Macros")
            .font(.title2.bold())
        
        HStack {
            InlinePicker(title: "Selected", selectedValue: $viewModel.selectedMacro,
                         possibleValues: viewModel.macros, onChange: { newValue in
                viewModel.selectedMacro = newValue
            })
            .labeledContentStyle(.accentedContent)
            
            Divider()
            
            Button {
                viewModel.deleteSelectedMacro()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(viewModel.selectedMacro == .none)
            .buttonStyle(.bordered)
            .foregroundStyle(Color.nordicRed)
            
            Divider()
            
            Button {
                // TODO
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(Color.universalAccentColor)
        }
        
        UARTSendMessageView()
            .fixedListRowSeparatorPadding()
        
        NavigationLink("All Messages (\(viewModel.messages.count))") {
            UARTMessagesList()
                .environmentObject(viewModel)
        }
        .foregroundStyle(Color.universalAccentColor)
    }
}
