//
//  UARTColor.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct UARTColor {
    enum ColorName: String, CaseIterable {
        case red, flame, orange, yellow, green, lake, blue, deepBlue1, deepBlue2, purple1, purple2, rose, grey1, grey2, nordic
        var allCases: [ColorName] {
            [.red, .flame, .orange, .yellow, .green, .lake, .blue, .deepBlue1, .deepBlue2, .purple1, .purple2, .rose, .grey1, .grey2, .nordic]
        }
    }
    
    let name: ColorName
    let color: UIColor
}

extension UARTColor: RawRepresentable {
    init?(colorNameString: String) {
        guard let name = ColorName(rawValue: colorNameString) else {
            return nil
        }
        
        self.init(rawValue: name)
    }
    
    init?(rawValue: ColorName) {
        self.name = rawValue
        
        guard let color = zip(ColorName.allCases, UIColor.UART.allColors)
            .first (where: { $0.0 == rawValue })?.1 else {
                return nil
        }
        
        self.color = color
    }
    
    typealias RawValue = ColorName
    var rawValue: ColorName { name }
}

extension UARTColor {
    static let red = UARTColor(rawValue: .red)!
    static let flame = UARTColor(rawValue: .flame)!
    static let orange = UARTColor(rawValue: .orange)!
    static let yellow = UARTColor(rawValue: .yellow)!
    static let green = UARTColor(rawValue: .green)!
    static let lake = UARTColor(rawValue: .lake)!
    static let blue = UARTColor(rawValue: .blue)!
    static let deepBlue1 = UARTColor(rawValue: .deepBlue1)!
    static let deepBlue2 = UARTColor(rawValue: .deepBlue2)!
    static let purple1 = UARTColor(rawValue: .purple1)!
    static let purple2 = UARTColor(rawValue: .purple2)!
    static let rose = UARTColor(rawValue: .rose)!
    static let grey1 = UARTColor(rawValue: .grey1)!
    static let grey2 = UARTColor(rawValue: .grey2)!
    static let nordic = UARTColor(rawValue: .nordic)!
}
