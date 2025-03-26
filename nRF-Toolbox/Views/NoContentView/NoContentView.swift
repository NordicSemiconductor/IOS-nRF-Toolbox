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
        case normal, tinted, error
        
        var tintColor: Color {
            switch self {
            case .normal:
                return .secondary
            case .tinted:
                return .nordicBlue
            case .error:
                return .nordicRed
            }
        }
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
            ContentUnavailableView {
                Label("No messages", systemImage: "exclamationmark.icloud")
                    .labelStyle(.coloredNoContentView(style.tintColor))
            } description: {
                Text("Unable to receive new messages")
                    .font(.callout)
            }
        }
        .padding()
    }
}

// MARK: - LabelStyle

fileprivate struct ColoredNoContentViewLabelStyle: LabelStyle {
    
    let color: Color
    
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center) {
            configuration.icon
                .scaleEffect(2.0, anchor: .center)
                .frame(size: CGSize(width: 60.0, height: 60.0))
                .foregroundColor(color)
            
            configuration.title
                .bold()
        }
        .font(.title)
    }
}

fileprivate extension LabelStyle where Self == ColoredNoContentViewLabelStyle {
    
    static func coloredNoContentView(_ color: Color) -> ColoredNoContentViewLabelStyle {
        ColoredNoContentViewLabelStyle(color: color)
    }
}
