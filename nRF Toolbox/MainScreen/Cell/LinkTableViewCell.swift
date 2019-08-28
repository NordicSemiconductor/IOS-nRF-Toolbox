//
//  LinkTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class LinkTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17)
        detailTextLabel?.font = UIFont.gtEestiDisplay(.thin, size: 12)
        detailTextLabel?.numberOfLines = 0
        
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with model: LinkService) {
        textLabel?.text = model.name
        detailTextLabel?.text = model.description
    }

}
