//
//  Color.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

public struct Color {
    public enum ColorName: String, CaseIterable {
        case red, flame, orange, yellow, green, lake, blue, deepBlue1, deepBlue2, purple1, purple2, rose, grey1, grey2, nordic
        var allCases: [ColorName] {
            [.red, .flame, .orange, .yellow, .green, .lake, .blue, .deepBlue1, .deepBlue2, .purple1, .purple2, .rose, .grey1, .grey2, .nordic]
        }
    }
    
    public let name: ColorName
    public let color: UIColor
}

extension Color: RawRepresentable {
    public typealias RawValue = ColorName
    public var rawValue: ColorName { name }
    
    init?(colorNameString: String) {
        guard let name = ColorName(rawValue: colorNameString) else {
            return nil
        }
        
        self.init(rawValue: name)
    }
    
    public init?(rawValue: ColorName) {
        self.name = rawValue
        
        guard let color = zip(ColorName.allCases, UIColor.UART.allColors)
            .first (where: { $0.0 == rawValue })?.1 else {
                return nil
        }
        
        self.color = color
    }
}

extension Color: CaseIterable {
    static let red = Color(rawValue: .red)!
    static let flame = Color(rawValue: .flame)!
    static let orange = Color(rawValue: .orange)!
    static let yellow = Color(rawValue: .yellow)!
    static let green = Color(rawValue: .green)!
    static let lake = Color(rawValue: .lake)!
    static let blue = Color(rawValue: .blue)!
    static let deepBlue1 = Color(rawValue: .deepBlue1)!
    static let deepBlue2 = Color(rawValue: .deepBlue2)!
    static let purple1 = Color(rawValue: .purple1)!
    static let purple2 = Color(rawValue: .purple2)!
    static let rose = Color(rawValue: .rose)!
    static let grey1 = Color(rawValue: .grey1)!
    static let grey2 = Color(rawValue: .grey2)!
    static let nordic = Color(rawValue: .nordic)!
    
    public static var allCases: [Color] {
        [.red, .flame, .orange, .yellow, .green, .lake, .blue, .deepBlue1, .deepBlue2, .purple1, .purple2, .rose, .grey1, .grey2, .nordic]
    }
}
