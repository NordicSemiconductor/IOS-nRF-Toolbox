//
//  UIColor+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 20/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIColor {
    static let _nordicBlue: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicBlue")!
        } else {
            return UIColor.black
        }
    }()
}
