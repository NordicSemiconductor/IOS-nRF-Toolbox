//
//  IridescenceModifier.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 11/3/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - IridescenceView

@available(iOS 17.0, macCatalyst 17.0, *)
public struct IridescenceView<Content: View>: View {
    
    // MARK: Private Properties
    
    @State private var start: Date = .now
    
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
                        .colorEffect(ShaderLibrary.iridescence(
                            .float2(proxy.size),
                            .float(timeSince)
                        ))
                }
        }
    }
}

// MARK: - ViewModifier

@available(iOS 17.0, macCatalyst 17.0, *)
public struct IridescenceModifier: ViewModifier {
  
    public func body(content: Content) -> some View {
        IridescenceView { content }
    }
}

@available(iOS 17.0, macCatalyst 17.0, *)
public extension View {
      
    func iridescence() -> some View {
        modifier(IridescenceModifier())
    }
}
