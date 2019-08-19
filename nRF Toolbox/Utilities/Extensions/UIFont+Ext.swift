//
//  UIFont+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum FontWeight: String {
    case ultraLight
    case mediumItalic
    case light
    case bold
    case ultraLightItalic
    case ultraBoldItalic
    case ultraBold
    case regular
    case lightItalic
    case thin
    case medium
    case boldItalic
    case regularItalic
    case thinItalic
    
    var name: String {
        return self.rawValue.prefix(1).uppercased() + self.rawValue.dropFirst()
    }
}

extension UIFont {
    static func gtEestiDisplay(_ weight: FontWeight, size: CGFloat) -> UIFont {
        let fontName = "GTEestiDisplay-" + weight.name
        return UIFont(name: fontName, size: size)!
    }
}
