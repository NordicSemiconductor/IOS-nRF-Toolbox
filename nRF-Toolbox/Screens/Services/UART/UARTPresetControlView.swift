//
//  UARTPresetControlView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 13/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import TipKit

// MARK: - UARTPresetControlView

struct UARTPresetControlView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Properties
    
    private let presets: UARTPresets
    
    // MARK: Init
    
    init(_ presets: UARTPresets) {
        self.presets = presets
    }
    
    // MARK: view
    
    var body: some View {
        HStack(spacing: 16) {
            UARTPresetsGridView(presets: presets, onTap: { i in
                viewModel.runCommand(presets.commands[i])
            }, onLongPress: { i in
                // No-op.
            })
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 8)

            VStack(spacing: 16) {
                ShareLink(item: viewModel.selectedPresets.url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }
                
                Button {
                    viewModel.showEditPresetsSheet = true
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                .tint(.primary)

                if viewModel.isPlayInProgress {
                    Button {
                        viewModel.stop()
                    } label: {
                        Image(systemName: "stop")
                            .font(.title2)
                    }
                    .tint(.nordicBlue)
                } else {
                    Button {
                        viewModel.play()
                    } label: {
                        Image(systemName: "play")
                            .font(.title2)
                    }
                    .tint(.nordicBlue)
                }
            }
        }
    }
}
