//
//  UARTMacrosHeaderView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosHeaderView: UIView, XibInstantiable {
    var editAction: (() -> ())!
    
    @IBAction private func editBtnPressed() {
        editAction()
    }
}
