//
//  UARTMacrosCollectionViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import UART

class UARTMacrosCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var commandsLabel: UILabel!
    @IBOutlet private var imageStack: UIStackView!
    @IBOutlet private var macroColorView: UIView!
    
    private var macro: Macros!
    private var gradientLayer = CAGradientLayer()
    
    var editMacros: ((Macros) -> ())?
    
    @IBAction private func editButtonPressed() {
        editMacros?(macro)
    }
    
    func applyMacro(_ macro: Macros) {
        self.macro = macro
        
        nameLabel.text = macro.name
        commandsLabel.text = "\(macro.elements.count) commands"
        
        imageStack
            .arrangedSubviews.compactMap { $0 as? UIImageView }
            .forEach { $0.image = nil }
        
        let commands = macro.elements.compactMap { element -> Command? in
            switch element {
            case .commandContainer(let command):
                return command.command
            default:
                return nil
            }
        }
        
        zip(
            commands.prefix(3),
            imageStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        )
        .forEach {
            $0.1.image = $0.0.image
        }
        
        if macroColorView.layer.sublayers?.contains(gradientLayer) != true {
            macroColorView.layer.insertSublayer(gradientLayer, at: 0)
            gradientLayer.frame = macroColorView.layer.bounds
            macroColorView.layer.masksToBounds = true
        }
        
        gradientLayer.colors = [
            macro.color.color.adjust(by: 0.05)!.cgColor,
            macro.color.color.adjust(by: -0.01)!.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        
    }

}
