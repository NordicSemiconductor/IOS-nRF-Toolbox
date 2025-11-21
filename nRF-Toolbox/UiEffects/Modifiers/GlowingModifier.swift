//
//  GlowingModifier.swift
//  iOSCommonLibraries
//
//  Created by Dinesh Harjani on 19/4/22.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - GlowingView

public struct GlowingView<Content: View>: View {
    
    // MARK: Private Properties
    
    @State private var glowOpacity: Double = Constants.maxGlowOpacity
    @State private var contentOpacity: Double = Constants.maxContentOpacity
    
    private let content: () -> Content
    private let animated: Bool
  
    // MARK: init
    
    public init(animated: Bool, content: @escaping () -> Content) {
        self.animated = animated
        self.content = content
    }
  
    // MARK: view
    
    public var body: some View {
        ZStack {
            content()
                .blur(radius: 5)
                .opacity(glowOpacity)
                .transition(.opacity)
            
            content()
                .opacity(contentOpacity)
                .transition(.opacity)
        }
        .onAppear {
            guard animated else { return }
            let baseAnimation = Animation.easeInOut(duration: Constants.duration)
            let repeated = baseAnimation.delay(Constants.delay).repeatForever(autoreverses: true)
            withAnimation(repeated) {
                self.glowOpacity = Constants.minGlowOpacity
                self.contentOpacity = Constants.minContentOpacity
            }
        }
    }
}

// MARK: - ViewModifier

public struct GlowingModifier: ViewModifier {
  
    private let animated: Bool
    
    public init(animated: Bool = true) {
        self.animated = animated
    }
    
    public func body(content: Content) -> some View {
        GlowingView(animated: animated) { content }
    }
}

public extension View {
      
    func glow(animated: Bool = true) -> some View {
        modifier(GlowingModifier(animated: animated))
    }
}

// MARK: - Constants

private enum Constants {
    
    static let duration = 3.0
    static let delay = 2.0
    
    static let minGlowOpacity = 0.0
    static let maxGlowOpacity = 1.0
    
    static let minContentOpacity = 0.8
    static let maxContentOpacity = 1.0
}
