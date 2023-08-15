//
//  HUD.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 15/08/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

struct HUD<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(16)
            .background(
                Capsule()
                    .foregroundColor(Color.secondarySystemBackground)
                    .shadow(color: Color(.secondaryLabel).opacity(0.16), radius: 12, x: 0, y: 5)
            )
    }
}

extension View {
    func hud<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .top) {
            self
            
            if isPresented.wrappedValue {
                HUD(content: content)
                    .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                    .zIndex(Double(Int.max))
            }
        }
    }
}

final class HUDState: ObservableObject {
    @Published var isPresented: Bool = false
    private(set) var title: String = ""
    private(set) var systemImage: String = ""
    
    func show(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
        withAnimation {
            isPresented = true
        }
    }
}

struct HUD_Previews: PreviewProvider {
    static var previews: some View {
        HUD {
            Label("Label", systemImage: "pencil.tip.crop.circle")
        }
    }
}
