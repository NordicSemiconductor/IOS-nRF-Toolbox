//
//  MacrosAddNewCommand.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class MacrosAddNewCommand: UIView, XibInstantiable {
    @IBOutlet private var addButton: UIButton!
    
    var addButtonCallback: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        addButton.contentVerticalAlignment = .fill
//        addButton.contentHorizontalAlignment = .fill
    }
    
    @IBAction private func addButtonClicked(_ sender: UIButton) {
        addButtonCallback?()
    }
}
