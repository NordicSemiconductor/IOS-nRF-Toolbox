//
//  UARTMacroWaitCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 14/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacroWaitCell: UITableViewCell {

    @IBOutlet var intervalLabel: ArgumentLabel!
    
    var timeIntervalChanged: ((Int) -> ())?
    var presentController: ((ArgumentLabel, UARTIncrementViewController) -> ())?
    var removeAction: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        intervalLabel.labelDidPressed = { [weak self] label, controller in
            self?.presentController?(label, controller)
        }
        
        intervalLabel.stepperValueChanged = { [weak self] ti in
            self?.timeIntervalChanged?(ti)
        }
        
    }
    
    @IBAction private func remove() {
        removeAction?()
    }
    
}
