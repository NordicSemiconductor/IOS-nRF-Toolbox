//
//  UARTMessagesList.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 14/4/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - UARTMessagesList

struct UARTMessagesList: View {
    
    // MARK: EnvironmentObject
    
    @EnvironmentObject private var viewModel: UARTViewModel
    
    // MARK: Properties
    
    @State private var showNewMacroAlert: Bool = false
    @State private var newMacroName: String = ""
    
    // MARK: view
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section("Oldest First") {
                    ForEach(viewModel.messages, id: \.timestamp) { message in
                        UARTMessageView(message)
                            .listRowSeparator(.hidden)
                    }
                    
                    Text("...")
                        .id(Date.Pongo)
                        .onChange(of: viewModel.messages, initial: false) { _, _  in
                            withAnimation {
                                proxy.scrollTo(Date.Pongo, anchor: .bottom)
                            }
                        }
                }
            }
            .listRowInsets(EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
            .listRowSpacing(0.0)
            
            VStack(alignment: .leading) {
                Text("Macros")
                    .font(.title2.bold())
                
                HStack {
                    InlinePicker(title: "Selected", selectedValue: $viewModel.selectedMacro,
                                 possibleValues: viewModel.macros, onChange: { newValue in
                        viewModel.selectedMacro = newValue
                    })
                    .labeledContentStyle(.accentedContent)

                    Button {
                        viewModel.deleteSelectedMacro()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.selectedMacro == .none)
                    .buttonStyle(.bordered)
                    .foregroundStyle(Color.nordicRed)
                    
                    Button {
                        newMacroName = ""
                        showNewMacroAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(Color.universalAccentColor)
                }
                
                if viewModel.selectedMacro != .none {
                    viewModel.selectedMacro
                }
                
                Divider()
                
                UARTSendMessageView()
            }
            .padding(.horizontal, 20)
        }
        .alert("New Macro", isPresented: $showNewMacroAlert) {
            TextField("Type Name Here", text: $newMacroName)
            
            Button("Cancel", role: .cancel) {
                showNewMacroAlert = false
            }
            
            Button("Add") {
                viewModel.newMacro(named: newMacroName)
                newMacroName = ""
                showNewMacroAlert = false
            }
        }
        .navigationTitle("UART Messages")
        .toolbar {
            Button("", systemImage: "list.bullet.rectangle.portrait") {
                Task { @MainActor in
                    viewModel.clearReceivedMessages()
                }
            }
        }
    }
}

// MARK: - Private

fileprivate extension Date {

    static let Pongo = Date(timeIntervalSince1970: 1113988039)
}

