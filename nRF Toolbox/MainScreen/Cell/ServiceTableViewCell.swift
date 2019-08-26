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
        self.name.text = model.name
        self.code.text = model.code
        self.icon.image = UIImage(named: model.icon)?.withRenderingMode(.alwaysTemplate)
    }
    
}
