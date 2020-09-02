//
//  AddSiriShortcutTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import IntentsUI
import Intents
import UARTMacrosExtension
import UART
import CoreSpotlight
import MobileCoreServices

public let kRuShortcut = "com.nordicsemi.runshortcut"

extension UART.Macros {
    @available(iOS 12.0, *)
    public static func newArticleShortcut(with thumbnail: UIImage?, macrosName: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: kRuShortcut)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(kRuShortcut)
        
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        // Title
        activity.title = "Run \(macrosName) Macros"
        
        // Subtitle
        attributes.contentDescription = "Run UART macros"
        
        // Thumbnail
        attributes.thumbnailData = thumbnail?.jpegData(compressionQuality: 1.0)
        
        // Suggested Phrase
        activity.suggestedInvocationPhrase = "Run macros"
        
        activity.contentAttributeSet = attributes
        return activity
    }
}

@available(iOS 12.0, *)
class AddSiriShortcutTableViewCell: UITableViewCell {
    
    weak var shortcutDelegate: INUIAddVoiceShortcutButtonDelegate? {
        didSet {
            siriBtn?.delegate = shortcutDelegate
        }
    }
    
    private var siriBtn: INUIAddVoiceShortcutButton?
    
    func apply(_ modelName: String) {
        addSiriButton(to: self.contentView, macrosName: modelName)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSiriButton(to view: UIView, macrosName: String) {
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        
        let img = UIImage(named: "FeatureUART")
        let activity = Macros.newArticleShortcut(with: img, macrosName: macrosName)
        
        button.shortcut = INShortcut.init(userActivity: activity)
        button.delegate = shortcutDelegate
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        
        self.siriBtn = button
    }
    
}
