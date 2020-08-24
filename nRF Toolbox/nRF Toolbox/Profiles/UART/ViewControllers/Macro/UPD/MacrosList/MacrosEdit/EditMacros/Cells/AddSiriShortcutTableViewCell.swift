//
//  AddSiriShortcutTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import IntentsUI

@available(iOS 12.0, *)
class AddSiriShortcutTableViewCell: UITableViewCell {
    
    weak var shortcutDelegate: INUIAddVoiceShortcutButtonDelegate? {
        didSet {
            siriBtn?.delegate = shortcutDelegate
        }
    }
    
    private var siriBtn: INUIAddVoiceShortcutButton?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSiriButton(to: self.contentView)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSiriButton(to view: UIView) {
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        //            button.shortcut = INShortcut(intent: intent )
        button.delegate = shortcutDelegate
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        
        self.siriBtn = button
    }
    
}
