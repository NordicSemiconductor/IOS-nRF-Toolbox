//
//  NordicBottomDetailsTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NordicBottomDetailsTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        textLabel?.setNordicFont()
        detailTextLabel?.setNordicFont()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
