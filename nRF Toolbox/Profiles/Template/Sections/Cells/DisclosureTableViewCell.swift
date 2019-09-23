//
//  DisclosureTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 13/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DisclosureTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17.0)
        self.accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
