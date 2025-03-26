//
//  NoContentView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 06/11/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - NoContentView

public struct NoContentView: View {
    
    // MARK: Style
    
    public enum Style {
        case normal, error
    }
    
    // MARK: Private Properties
    
    private let title: String
    private let systemImage: String
    private let description: String?
    private let style: Style
    
    // MARK: init
    
    init(title: String, systemImage: String, description: String? = nil, style: Style = .normal) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.style = style
    }
    
    // MARK: view
    
    public var body: some View {
        VStack {
            switch style {
            case .normal:
                customView
//                        .foregroundStyle(Color.nordicBlue)
            case .error:
                customView
                    .foregroundStyle(Color.nordicRed)
            }
        }
        .padding()
    }
    
    @available(macOS 14.0, *)
    @available(iOS 17.0, *)
    @ViewBuilder
    private var customView: some View {
        VStack {
            if let description {
                ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
            } else {
                ContentUnavailableView(title, systemImage: systemImage)
            }
        }
    }
}
