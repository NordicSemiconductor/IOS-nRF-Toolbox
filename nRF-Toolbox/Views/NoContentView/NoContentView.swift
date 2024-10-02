//
//  NoContentView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 06/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

//fileprivate typealias OldNoContent = iOS_Common_Libraries.ContentUnavailableView

struct NoContentView: View {
    enum Style {
        case normal, error
    }
    
    let title: String
    let systemImage: String
    let description: String?
    let style: Style
    
    init(title: String, systemImage: String, description: String? = nil, style: Style = .normal) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.style = style
    }
    
    var body: some View {
        VStack {
            if #available(iOS 17, macOS 14, *) {
                switch style {
                case .normal:
                    new
//                        .foregroundStyle(Color.nordicBlue)
                case .error:
                    new
                        .foregroundStyle(Color.nordicRed)
                }
            } else {
                old
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var old: some View {
        Text("Content Not Available")
//        OldNoContent(configuration:
//                        ContentUnavailableConfiguration(
//                            text: title,
//                            secondaryText: description,
//                            systemName: systemImage
//                        )
//        )
    }
    
    @available(macOS 14.0, *)
    @available(iOS 17.0, *)
    @ViewBuilder
    private var new: some View {
        VStack {
            if let description {
                ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
            } else {
                ContentUnavailableView(title, systemImage: systemImage)
            }
        }
    }
}

#Preview {
    NoContentView(
        title: "Item is not selected", systemImage: "binoculars.fill", description: "Select an item"
    )
}

#Preview {
    NoContentView(
        title: "Error", systemImage: "exclamationmark.triangle", style: .error
    )
}
