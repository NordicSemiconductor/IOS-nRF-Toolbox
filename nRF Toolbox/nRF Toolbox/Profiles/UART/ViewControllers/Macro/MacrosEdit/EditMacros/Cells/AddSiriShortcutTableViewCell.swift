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
import UART

@available(iOS 12.0, *)
class AddSiriShortcutTableViewCell: UITableViewCell {
    
    weak var shortcutDelegate: INUIAddVoiceShortcutButtonDelegate? {
        didSet {
            siriBtn?.delegate = shortcutDelegate
        }
    }
    
    private var siriBtn: INUIAddVoiceShortcutButton?
    
    func apply(_ macros: UART.Macros) {
        addSiriButton(to: self.contentView, macros: macros)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSiriButton(to view: UIView, macros: UART.Macros) {
        
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        
        let activity = macros.userActivity()
        
        button.shortcut = INShortcut.init(userActivity: activity)
        button.delegate = shortcutDelegate
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        
        self.siriBtn = button
    }
    
}
