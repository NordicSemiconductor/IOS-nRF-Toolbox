//
//  BlinkingModifier.swift
//  iOSCommonLibraries
//
//  Created by Dinesh Harjani on 17/10/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - BlinkingView

public struct BlinkingView<Content: View>: View {
    
    // MARK: Private Properties
    
    @State private var blink: Bool = false
    
    private let content: () -> Content
  
    // MARK: init
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
  
    // MARK: view
    
    /**
     Yes, there's a deprecated API warning. But the non-deprecated API doesn't animate correctly.
     */
    public var body: some View {
        content()
            .opacity(blink ? Constants.maxBlinkOpacity : Constants.minBlinkOpacity)
            .scaleEffect(blink ? Constants.maxBlinkScale : Constants.minBlinkScale)
            .animation(Animation.linear(duration: Constants.duration).repeatForever(autoreverses: true), value: blink)
            .onAppear {
                withAnimation {
                    blink = true
                }
            }
    }
}

// MARK: - ViewModifier

public struct BlinkingModifier: ViewModifier {
  
    public func body(content: Content) -> some View {
        BlinkingView { content }
    }
}

public extension View {
      
    func blink() -> some View {
        modifier(BlinkingModifier())
    }
}

// MARK: - Constants

private enum Constants {
    
    static let duration: TimeInterval = 0.8
    
    static let minBlinkOpacity = 0.2
    static let maxBlinkOpacity = 1.0
    static let minBlinkScale = 0.95
    static let maxBlinkScale = 1.0
}
