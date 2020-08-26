//
//  UIColor+Ext.swift
//  UART
//
//  Created by Nick Kibysh on 24/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import Core

extension UIColor {
    struct UART {
        static let red = UIColor(lightHex: 0xD36B6A, darkHex: 0xCE5A5B)
        static let flame = UIColor(lightHex: 0xD5755C, darkHex: 0xD86D50)
        static let orange = UIColor(lightHex: 0xCC7E49, darkHex: 0xD07C45)
        static let yellow = UIColor(lightHex: 0xC99842, darkHex: 0xCB9842)
        static let green = UIColor(lightHex: 0x739E54, darkHex: 0x6F9B4E)
        static let lake = UIColor(lightHex: 0x649B87, darkHex: 0x5E9C88)
        static let blue = UIColor(lightHex: 0x6895A7, darkHex: 0x6899AC)
        static let deepBlue1 = UIColor(lightHex: 0x6E8ABA, darkHex: 0x6B8CBE)
        static let deepBlue2 = UIColor(lightHex: 0x6E76B9, darkHex: 0x6C76BE)
        static let purple1 = UIColor(lightHex: 0x8470B4, darkHex: 0x8266C6)
        static let purple2 = UIColor(lightHex: 0xAD76B9, darkHex: 0xB16BBC)
        static let rose = UIColor(lightHex: 0xC9718B, darkHex: 0xD3718B)
        static let grey1 = UIColor(lightHex: 0x7F8994, darkHex: 0x737B86)
        static let grey2 = UIColor(lightHex: 0x858B88, darkHex: 0x7C837E)
        static let nordic = UIColor(lightHex: 0x938A85, darkHex: 0x938A85)
        
        static var allColors: [UIColor] = [red, flame, orange, yellow, green, lake, blue, deepBlue1, deepBlue2, purple1, purple2, rose, grey1, grey2, nordic]
    }
}
