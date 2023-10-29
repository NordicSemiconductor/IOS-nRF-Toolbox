//
//  HeartRateScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

private typealias Env = HeartRateScreen.ViewModel.Environment

struct HeartRateScreen: View {

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        HeartRateView()
            .environmentObject(viewModel.env)
            .task {
                await viewModel.prepare()
            }
    }
}

struct HeartRateView: View {
    @EnvironmentObject private var environment: Env
    
    var body: some View {
        if environment.data.isEmpty {
            ContentUnavailableView(configuration: ContentUnavailableConfiguration(text: "No HR Data", systemName: "waveform.path.ecg.rectangle"))
        } else {
            HeartRateChart()
        }
    }
}

#Preview {
    HeartRateView()
        .environmentObject(Env())
}
