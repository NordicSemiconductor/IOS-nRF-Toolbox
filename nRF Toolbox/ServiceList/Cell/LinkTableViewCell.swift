//
//  LinkTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class LinkTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17)
        self.detailTextLabel?.font = UIFont.gtEestiDisplay(.thin, size: 12)
        self.detailTextLabel?.numberOfLines = 0
        
    }

}
