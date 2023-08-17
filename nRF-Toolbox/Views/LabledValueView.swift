//
//  LabledValueView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct LabledValue {
    var icon: Image?
    var text: String
    var value: String
    var isActive: Bool
    var color: Color
    
    init(icon: Image? = nil, text: String, value: String, isActive: Bool, color: Color) {
        self.icon = icon
        self.text = text
        self.value = value
        self.isActive = isActive
        self.color = color
    }
    
    init(systemName: String, text: String, value: String, isActive: Bool, color: Color) {
        self.icon = Image(systemName: systemName)
        self.text = text
        self.value = value
        self.isActive = isActive
        self.color = color
    }
    
    mutating func updateValue(_ newValue: String, isActive: Bool = true) {
        self.value = newValue
        self.isActive = isActive
    }
}

struct LabledValueView: View {
    let someValue: LabledValue
    
    var body: some View {
        HStack {
            Label {
                Text(someValue.text)
            } icon: {
                someValue.icon?.foregroundColor(color)
            }

            Spacer()
            Text(someValue.value)
        }
        .disabled(!someValue.isActive)
    }
    
    var color: Color {
        someValue.isActive ? someValue.color : Color.gray
    }
}

struct SomeValueView_Previews: PreviewProvider {
    static var previews: some View {
        LabledValueView(someValue: LabledValue(systemName: "map.fill", text: "Total Distance", value: "10 km", isActive: true, color: .red))
    }
}
