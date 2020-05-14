//
//  UARTShortcutManager.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 14.05.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

public let kNewArticleActivityType = "com.razeware.NewArticle"

extension NSUserActivity {
    struct ActivityType {
        
    }
}

@available(iOS 12.0, *)
class UARTShortcutManager {
    public static func newArticleShortcut(thumbnail: UIImage?) -> NSUserActivity {
        let activity = NSUserActivity(activityType: kNewArticleActivityType)
        activity.persistentIdentifier =
            NSUserActivityPersistentIdentifier(kNewArticleActivityType)
        
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        return activity
    }
}
