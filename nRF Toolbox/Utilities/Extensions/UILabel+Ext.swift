//
//  UILabel+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UILabel {
    func setNordicFont(weight: FontWeight = .regular) {
        let currentFontSize = self.font.pointSize
        font = UIFont.gtEestiDisplay(weight, size: currentFontSize)
    }
}
