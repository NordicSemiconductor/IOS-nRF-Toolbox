//
//  StateViews.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import iOS_Common_Libraries

struct StateViews {
    struct Unsupported: View {
        var body: some View {
            ContentUnavailableView(
                configuration: ContentUnavailableConfiguration(
                    text: "Bluetooth is Unavailable",
                    secondaryText: "It looks like your device doesn't support bluetooth",
                    systemName: "hand.thumbsdown"
                )
            )
            .padding()
        }
    }
    
    struct Unauthorized: View {
        var body: some View {
            ContentUnavailableView(
                configuration: ContentUnavailableConfiguration(
                    text: "No Permission Granted",
                    secondaryText: "Bluetooth is not authorized. Open settings and give access the application to use Bluetooth.",
                    systemName: "xmark.seal"
                ),
                actions: {
                    Button("Open Settings") {
                        // TODO: Open Settings
                    }
                    .buttonStyle(NordicSecondary())
                }
            )
            .padding()
        }
    }
    
    struct Disabled: View {
        var body: some View {
            ContentUnavailableView(
                configuration: ContentUnavailableConfiguration(
                    text: "Bluetooth is Turned Off",
                    secondaryText: "It looks like Bluetooth is turnd off. You can turn it on in Settings",
                    systemName: "gear"
                ),
                actions: {
                    Button("Open Settings") {
                        // TODO: Open Settings
                    }
                    .buttonStyle(NordicSecondary())
                }
            )
            .padding()
        }
    }
    
    struct EmptyResults: View {
        var body: some View {
            ContentUnavailableView(
                configuration: ContentUnavailableConfiguration(
                    text: "Scanning ...",
                    systemName: "binoculars"
                )
            )
        }
    }
}

#Preview {
    StateViews.Unsupported()
}
