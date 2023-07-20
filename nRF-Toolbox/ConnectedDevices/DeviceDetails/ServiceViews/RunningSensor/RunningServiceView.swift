//
//  RunningServiceView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_BLE_Library
import CoreBluetoothMock

struct RunningServiceView: View {
    @ObservedObject var viewModel: RunningServiceHandler
    private let formatter = MeasurementFormatter()
    
    var body: some View {
        VStack(alignment: .leading) {
            SomeValueView(someValue: viewModel.instantaneousSpeed)
            SomeValueView(someValue: viewModel.instantaneousCadence)
            SomeValueView(someValue: viewModel.instantaneousStrideLength)
            SomeValueView(someValue: viewModel.totalDistance)
        }
//        .padding()
        .background(.yellow.opacity(0.15))
        .cornerRadius(12)
    }
}

struct RunningServiceView_Previews: PreviewProvider {
    static var previews: some View {
        RunningServiceView(viewModel: RunningServiceHandlerPreview()!)
    }
}
