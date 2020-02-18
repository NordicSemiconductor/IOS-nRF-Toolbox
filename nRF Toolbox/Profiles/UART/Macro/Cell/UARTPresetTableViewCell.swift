//
//  UARTPresetTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 14/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTPresetTableViewCell: UITableViewCell {
    
    @IBOutlet var presetCollectionView: UARTPresetCollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated) 
    }
    
    func apply(preset: UARTPreset, delegate: UARTPresetCollectionViewDelegate?) {
        presetCollectionView.preset = preset
        presetCollectionView.presetDelegate = delegate
    }
    
}

