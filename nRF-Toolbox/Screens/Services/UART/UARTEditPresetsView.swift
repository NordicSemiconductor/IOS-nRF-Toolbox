//
//  UARTEditPresetsView.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 15/5/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries
import AEXML

// MARK: - UARTEditPresetsView

struct UARTEditPresetsView: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Private Properties
    
    @State private var name: String = ""
    @State private var sequence: [UARTPreset] = [UARTPreset]()
    @State private var showFileExporter = false

    private let appLog = NordicLog(category: #file)
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Name") {
                CancellableTextField("Type preset's set name here", cancelText: name, icon: .text, text: $name)
                    .keyboardType(.alphabet)
                    .submitLabel(.done)
                    .onSubmit {
                        save()
                    }
            }
            
            Section("Presets") {
                UARTPresetsGridView(presets: viewModel.selectedPresets, onTap: { i in
                    viewModel.editCommandIndex = i
                    viewModel.showEditPresetSheet = true
                }, onLongPress: { i in
                    guard viewModel.selectedPresets.commands[i].data != nil else { return }
                    sequence.append(viewModel.selectedPresets.commands[i])
                })
                .aspectRatio(1, contentMode: .fit)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section("Command Sequence") {
                Text ("Tip: Long press command to add it to a sequence.")
                    .foregroundColor(.secondary)
                    .font(Font.caption.bold())
                ForEach(sequence, id: \.self) { command in
                    Text(command.toString() ?? "N/A")
                }
                
                Button("Add Delay") {
                    
                }
                .tint(.universalAccentColor)
                .centered()
            }
            
            Section {
                Button("Save") {
                    viewModel.showEditPresetsSheet = false
                    // onDisappear will trigger a save.
                }
                .tint(.universalAccentColor)
                .centered()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit \(viewModel.selectedPresets.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    viewModel.showEditPresetsSheet = false
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export", systemImage: "square.and.arrow.up") {
                    showFileExporter = true
                }
            }
        }
        .doOnce {
            name = viewModel.selectedPresets.name
        }
        .onDisappear {
            save()
        }
        .fileExporter(
            isPresented: $showFileExporter,
            document: XMLFileDocument(content: viewModel.selectedPresetsXml),
            contentType: .xml,
            defaultFilename: "\(viewModel.selectedPresets.name).xml"
        ) { result in
            switch result {
            case .success(let url):
                print("File saved to: \(url)")
            case .failure(let error):
                print("Error saving file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: API
    
    func save() {
        appLog.debug(#function)
        viewModel.savePresets()
    }
}
