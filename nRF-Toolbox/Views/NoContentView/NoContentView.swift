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
                Image(systemName: "exclamationmark.icloud")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: CGSize(width: 60.0, height: 60.0))
                    .foregroundStyle(style.tintColor)
                
                Text(title)
                    .font(.title)
                    .bold()
            } description: {
                Text(description ?? "")
                    .font(.callout)
            }
        }
        .padding()
    }
}
