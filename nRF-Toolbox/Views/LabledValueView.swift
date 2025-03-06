//
//  LabledValueView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 19/07/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - LabledValue

struct LabledValue {
    
    // MARK: Properties
    
    let icon: Image?
    let text: String
    let color: Color
    var value: String
    var isActive: Bool
    
    // MARK: init
    
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
    
    // MARK: updateValue
    
    mutating func updateValue(_ newValue: String, isActive: Bool = true) {
        self.value = newValue
        self.isActive = isActive
    }
}

// MARK: - LabledValueView

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
