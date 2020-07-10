//
//  UARTMacrosCollectionViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var commandsLabel: UILabel!
    @IBOutlet private var imageStack: UIStackView!
    @IBOutlet private var macroColorView: UIView!
    
    private var macro: UARTMacro!
    private var gradientLayer = CAGradientLayer()
    
    var editMacros: ((UARTMacro) -> ())?
    
    @IBAction private func editButtonPressed() {
        editMacros?(macro)
    }
    
    func applyMacro(_ macro: UARTMacro) {
        self.macro = macro
        
        nameLabel.text = macro.name
        commandsLabel.text = "\(macro.commands.count) commands"
        
        imageStack
            .arrangedSubviews.compactMap { $0 as? UIImageView }
            .forEach { $0.image = nil }
        
        zip(
            macro.commands.prefix(3),
            imageStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        )
        .forEach {
            $0.1.image = $0.0.command.image
        }
        
//        macroColorView.backgroundColor = macro.color.color
        
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
