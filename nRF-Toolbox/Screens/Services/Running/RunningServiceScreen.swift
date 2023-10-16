//
//  RunningServiceScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 16/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct RunningServiceScreen: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RunningServiceView()
            .task {
                // TODO: Start Bluetooth tasks
            }
    }
}

struct RunningServiceView: View {
    var body: some View {
        Text("Running View")
    }
}

#Preview {
    RunningServiceView()
}
