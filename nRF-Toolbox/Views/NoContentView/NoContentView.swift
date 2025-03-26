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
    private let animated: Bool
    
    @State private var rotationAngle = 0.0
    
    // MARK: init
    
    init(title: String, systemImage: String, description: String? = nil,
         style: Style = .normal, animated: Bool = true) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.style = style
        self.animated = animated
    }
    
    // MARK: view
    
    public var body: some View {
        VStack {
            ContentUnavailableView {
                Image(systemName: systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: CGSize(width: 60.0, height: 60.0))
                    .foregroundStyle(style.tintColor)
                    .rotationEffect(Angle.degrees(rotationAngle))
                    .onAppear {
                        guard animated else { return }
                        startAnimations()
                    }
                
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
    
    // MARK: Animation
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            rotationAngle = -15.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle = 45.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                startAnimations()
            }
        }
    }
}
