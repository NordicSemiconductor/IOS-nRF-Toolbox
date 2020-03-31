//
//  BGMDisplayItemTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 01.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class BGMDisplayItemTableViewCell: UITableViewCell {
    
    var callback: ((Int) -> ())!
    
    @IBAction private func displayItemsChanges(sender: UISegmentedControl) {
        callback(sender.selectedSegmentIndex)
    }
    
}
