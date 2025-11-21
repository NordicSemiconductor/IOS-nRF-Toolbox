//
//  FlickerModifier.swift
//  iOSCommonLibraries
//  nRF-Connect
//
//  Created by Dinesh Harjani on 12/3/25.
//  Created by Dinesh Harjani on 16/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public struct FlickerView<Content: View>: View {
    
    // MARK: Private Properties
    
    @State private var start: Date = .now
    
    private let shaderLibrary = ShaderLibrary.bundle(.main)
    private let animationInterval: Double = 1 / 24
    private let content: () -> Content
  
    // MARK: Init
    
    init(content: @escaping () -> Content) {
        self.content = content
    }
    
    // MARK: view
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: animationInterval)) { timelineView in
            let timeSince = start.distance(to: timelineView.date)
            content()
                .visualEffect { content, proxy in
                    content
                        .colorEffect(shaderLibrary.flicker(
                            .float2(proxy.size),
                            .float(timeSince)
                        ))
                }
        }
    }
}

// MARK: - ViewModifier

@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public struct FlickerModifier: ViewModifier {
  
    public func body(content: Content) -> some View {
        FlickerView { content }
    }
}

@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public extension View {
      
    func flicker() -> some View {
        modifier(FlickerModifier())
    }
}
