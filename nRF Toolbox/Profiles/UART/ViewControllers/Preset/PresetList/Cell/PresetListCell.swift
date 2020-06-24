//
//  PresetListCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 23/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class PresetListCell: UICollectionViewCell {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var presetName: UILabel!
    @IBOutlet private var starImage: UIImageView!
    
    func apply(_ preset: UARTPreset, imageSize: CGSize) {
        presetName.text = preset.name
        imageView.image = preset.renderImage(size: imageSize)
        starImage.isHidden = !preset.isFavorite
    }
}
