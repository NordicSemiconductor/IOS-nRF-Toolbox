//
//  ServiceView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

struct ServiceView: View {
    let service: ServiceHandler
    
    var body: some View {
        switch service {
        case let running as RunningServiceHandler:
            RunningServiceView1(viewModel: running)
        default:
            fatalError()
        }
    }
}

struct ServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceView(service: RunningServiceHandlerPreview()!)
    }
}
