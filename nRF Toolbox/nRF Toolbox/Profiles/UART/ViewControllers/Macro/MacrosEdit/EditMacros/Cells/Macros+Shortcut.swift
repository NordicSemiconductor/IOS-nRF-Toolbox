//
//  Macros+Shortcut.swift
//  UARTMacrosExtension
//
//  Created by Nick Kibysh on 02/09/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import UART
import Intents
import CoreSpotlight
import MobileCoreServices

let kRuShortcut = "com.nordicsemi.runshortcut"

@available(iOS 12.0, *)
extension UART.Macros {
    public func userActivity() -> NSUserActivity {
        let id = "\(kRuShortcut).\(self.name)"
        let activity = NSUserActivity(activityType: id)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(id)
        
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        // Title
        activity.title = "Run \(self.name) Macros"
        
        // Subtitle
        attributes.contentDescription = "Run UART macros"
        
        let thumbnail = self.elements
            .compactMap { $0 as? Command }
            .first
            .map { $0.image }
            
        // Thumbnail
        attributes.thumbnailData = thumbnail??.jpegData(compressionQuality: 1.0)
        
        // Suggested Phrase
        activity.suggestedInvocationPhrase = "Run \(self.name) macros"
        
        activity.contentAttributeSet = attributes
        return activity
    }
}
