//
//  UARTMacroCommandCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import UART

private extension Command {
    var typeName: String {
        switch self {
        case is TextCommand: return "Text Command"
        case is DataCommand: return "Data Command"
        case is EmptyCommand: return "Empty Command"
        default: return ""
        }
    }
}

class UARTMacroCommandCell: UITableViewCell {
    @IBOutlet var icon: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var commandDescription: UILabel!
    
    @IBOutlet var deleteBtn: UIButton!
    @IBOutlet var expandBtn: UIButton!
    
    var expandAction: ((UIButton) -> ())?
    var deleteAction: ((UIButton) -> ())?
    
    func apply(_ command: Command) {
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
