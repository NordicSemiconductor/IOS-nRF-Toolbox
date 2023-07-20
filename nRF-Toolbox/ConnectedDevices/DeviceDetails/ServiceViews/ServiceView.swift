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
    let services: [ServiceHandler]
    
    var body: some View {
        List(services) { service in
            Section(
                content: {
                    ZStack(alignment: .topLeading) {
                        serviceView(service: service)
                            .background(.clear)
                        
                    }
                }, header: {
                    ServiceBadge(serviceRepresentatino: ServiceRepresentation(identifier: service.id)!)
                }
            )
        }
    }
    
    @ViewBuilder
    private func serviceView(service: ServiceHandler) -> some View {
        switch service {
        case let running as RunningServiceHandler:
            RunningServiceView(viewModel: running)
        default:
            EmptyView()
        }
    }
}

struct ServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceView(services: [RunningServiceHandlerPreview()!])
    }
}
