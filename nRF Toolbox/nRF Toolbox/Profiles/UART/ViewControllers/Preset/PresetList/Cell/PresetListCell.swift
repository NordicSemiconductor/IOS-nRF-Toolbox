//
//  PresetListCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 23/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import UART

class PresetListCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet private var presetName: UILabel!
    @IBOutlet private var starImage: UIImageView!
    
    func apply(_ preset: Preset, imageSize: CGSize) {
        presetName.text = preset.name
        imageView.image = preset.renderImage(size: imageSize)
        starImage.isHidden = !preset.isFavorite
    }
}
