//
//  ImageCollectionViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let bgView = UIView()
        let selectedBGView = UIView()
        if #available(iOS 13.0, *) {
            bgView.backgroundColor = .systemGray5
            selectedBGView.backgroundColor = .systemGray2
        } else {
            bgView.backgroundColor = .nordicGrey5
            selectedBGView.backgroundColor = .nordicGrey4
        }
        selectedBackgroundView = selectedBGView
        backgroundView = bgView
        imageView.tintColor = .nordicBlue
    }

}
