//
//  ImageWrapper.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 27.04.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIImage

struct ImageWrapper {
    var modernIcon: ModernIcon
    var legacyIcon: UIImage?
    
    var image: UIImage? {
        if #available(iOS 13, *) {
            return modernIcon.image
        } else {
            return legacyIcon
        }
    }
    
    init(icon: ModernIcon, image: UIImage?) {
        modernIcon = icon
        legacyIcon = image
    }
    
    init(icon: ModernIcon, imageName: String) {
        modernIcon = icon
        legacyIcon = UIImage(named: imageName)
    }
}
