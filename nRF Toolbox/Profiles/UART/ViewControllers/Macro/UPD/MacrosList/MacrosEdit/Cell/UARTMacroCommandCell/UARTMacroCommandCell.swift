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
    
    @IBOutlet var deleteBtn: UIButton!
    @IBOutlet var expandBtn: UIButton!
    
    var expandAction: ((UIButton) -> ())?
    var deleteAction: ((UIButton) -> ())?
    
    func apply(_ command: UARTCommandModel) {
        icon.image = command.image
        title.text = command.title
        commandDescription.text = command.typeName
    }
    
    @IBAction func deleteClicked(_ sender: UIButton) {
        deleteAction?(sender)
    }
    
    @IBAction func expandBtnClicked(_ sender: UIButton) {
        expandAction?(sender)
    }
    
}
