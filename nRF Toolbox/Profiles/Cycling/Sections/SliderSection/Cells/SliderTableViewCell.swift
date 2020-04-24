//
//  SliderTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 23.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class SliderTableViewCell: UITableViewCell {
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var title: UILabel!

    var action: ((Double) -> ())?
    
    @IBAction private func changedSliderValue(slider: UISlider) {
        action?(Double(slider.value))
    }
    
}
