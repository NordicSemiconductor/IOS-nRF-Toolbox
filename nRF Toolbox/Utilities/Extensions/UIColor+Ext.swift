//
//  UIColor+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIColor {
    public convenience init(hex: UInt) {
        let r = CGFloat((hex & 0xff0000) >> 16) / 255
        let g = CGFloat((hex & 0x00ff00) >> 8) / 255
        let b = CGFloat((hex & 0x0000ff)) / 255
        
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
    
    public convenience init(lightHex: UInt, darkHex: UInt) {
        if #available(iOS 13, *) {
            self.init { (traitCollection) -> UIColor in
                switch traitCollection.userInterfaceStyle {
                case .dark: return UIColor(hex: darkHex)
                default: return UIColor(hex: lightHex)
                }
            }
        } else {
            self.init(hex: lightHex)
        }
    }
    
    public func adjust(by lightIndex: CGFloat) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + lightIndex, 1.0),
                           green: min(green + lightIndex, 1.0),
                           blue: min(blue + lightIndex, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
