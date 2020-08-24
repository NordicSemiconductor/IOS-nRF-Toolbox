//
//  PresetListUtilityCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 25/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//
import UIKit

class PresetListUtilityCell: UICollectionViewCell {
    enum CellStyle {
        case blanc, export
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var title: UILabel!
    
    var type: CellStyle! {
        didSet {
            setType(type)
        }
    }
    
    private func setType(_ type: CellStyle) {
        switch type {
        case .blanc:
            imageView.image = ImageWrapper(icon: ModernIcon.doc, image: nil).image
            title.text = "New Preset"
        case .export:
            let icon: ModernIcon = ModernIcon.square(ModernIcon.and)(ModernIcon.arrow)(ModernIcon.down)
            imageView.image = ImageWrapper(icon: icon, image: nil).image
            title.text = "Export"
        }
    }
}
