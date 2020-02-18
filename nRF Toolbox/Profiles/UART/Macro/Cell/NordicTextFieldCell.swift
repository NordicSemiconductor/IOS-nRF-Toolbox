//
//  NordicTextFieldCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 18/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NordicTextFieldCell: UITableViewCell {
    var textChanged: ((String?) -> Void)?
    
    @IBAction func textChanged(_ sender: UITextField) {
        textChanged?(sender.text)
    }
}

extension NordicTextFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
