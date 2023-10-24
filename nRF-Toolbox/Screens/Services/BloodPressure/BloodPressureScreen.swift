//
//  BloodPressureScreen.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

private typealias Env = BloodPressureScreen.ViewModel.Environment

struct BloodPressureScreen: View {

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        BloodPressureView()
            .environmentObject(Env())
    }
}

struct BloodPressureView: View {
    @EnvironmentObject private var environment: Env

    var body: some View {
        Text("Hell BloodPressureView")
    }
}

#Preview {
    BloodPressureView()
        .environmentObject(Env())
}
