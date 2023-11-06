//
//  AttributeList.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 24/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Bluetooth_Numbers_Database

struct AttributeList: View {
    let attributes: [Attribute]
    
    var body: some View {
        if attributes.isEmpty {
            NoContentView(
                title: "Attributes not found",
                systemImage: "table")
        } else {
            List(attributes, id: \.id) {
                AttributeItemView(attribute: $0)
            }
        }
    }
}

#Preview {
    AttributeList(attributes: [
        Service.runningSpeedAndCadence,
        Characteristic.scControlPoint,
        Descriptor.gattCharacteristicUserDescription,
        Characteristic.rscMeasurement,
        Characteristic.rscFeature,
        Descriptor.gattCharacteristicUserDescription,
    ])
}

#Preview {
    AttributeList(attributes: [
    ])
}
