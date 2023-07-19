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
    
    /*
     let instantaneousSpeed: Measurement<UnitSpeed>
     let instantaneousCadence: Int
     let instantaneousStrideLength: Measurement<UnitLength>?
     let totalDistance: Measurement<UnitLength>?
     */
    
    var body: some View {
        speadView
    }
    
    @ViewBuilder
    var speadView: some View {
        Text("")
    }
}

struct RunningServiceView_Previews: PreviewProvider {
    static var previews: some View {
        RunningServiceView(viewModel: RunningServiceHandlerPreview()!)
    }
}
