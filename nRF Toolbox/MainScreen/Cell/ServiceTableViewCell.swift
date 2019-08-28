//
//  ServiceTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ServiceTableViewCell: UITableViewCell {
    @IBOutlet private var name: UILabel!
    @IBOutlet private var icon: UIImageView!
    @IBOutlet private var code: UILabel!
    
    func update(with model: BLEService) {
        name.text = model.name
        code.text = model.code
        icon.image = UIImage(named: model.icon)?.withRenderingMode(.alwaysTemplate)
        
        #if BETA
        if #available(iOS 13.0, *) {
            name.textColor = .label
            code.textColor = .secondaryLabel
        }
        #endif
        
    }
    
}
