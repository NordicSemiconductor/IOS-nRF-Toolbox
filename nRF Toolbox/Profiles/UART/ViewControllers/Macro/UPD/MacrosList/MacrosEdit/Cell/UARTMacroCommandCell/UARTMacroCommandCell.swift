//
//  UARTMacroCommandCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacroCommandCell: UITableViewCell {
    @IBOutlet var icon: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var commandDescription: UILabel!
    
    func apply(_ command: UARTCommandModel) {
        icon.image = command.image
        title.text = command.title
        commandDescription.text = command.typeName
    }
    
}
