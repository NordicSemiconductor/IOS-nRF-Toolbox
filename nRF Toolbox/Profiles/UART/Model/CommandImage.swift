//
//  CommandImage.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIImage

struct CommandImage: Codable, Equatable {
    static func == (lhs: CommandImage, rhs: CommandImage) -> Bool {
        lhs.name == rhs.name && lhs.systemIcon == rhs.systemIcon
    }
    
    var name: String
    var image: UIImage? {
        if #available(iOS 13, *), let image = systemIcon?.image {
            return image
        } else {
            return UIImage(named: self.name)?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var systemIcon: ModernIcon?
    
    init(name: String, modernIcon: ModernIcon? = nil) {
        self.name = name
        self.systemIcon = modernIcon
    }
}

extension CommandImage: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.name = value
        self.systemIcon = nil
    }
}

extension CommandImage: CaseIterable {
    static let allCases: [CommandImage] = [.pause, .play, .record, .repeat, .rewind, .start, .stop, .number1, .number2, .number3, .number4, .number5, .number6, .number7, .number8, .number9, .up, .down, .left, .right]
}

extension CommandImage {
    static let empty = CommandImage(name: "")
    static let number1 = CommandImage(name: "NUMBER_1", modernIcon: ModernIcon(digit: 1)(.circle))
    static let number2 = CommandImage(name: "NUMBER_2", modernIcon: ModernIcon(digit: 2)(.circle))
    static let number3 = CommandImage(name: "NUMBER_3", modernIcon: ModernIcon(digit: 3)(.circle))
    static let number4 = CommandImage(name: "NUMBER_4", modernIcon: ModernIcon(digit: 4)(.circle))
    static let number5 = CommandImage(name: "NUMBER_5", modernIcon: ModernIcon(digit: 5)(.circle))
    static let number6 = CommandImage(name: "NUMBER_6", modernIcon: ModernIcon(digit: 6)(.circle))
    static let number7 = CommandImage(name: "NUMBER_7", modernIcon: ModernIcon(digit: 7)(.circle))
    static let number8 = CommandImage(name: "NUMBER_8", modernIcon: ModernIcon(digit: 8)(.circle))
    static let number9 = CommandImage(name: "NUMBER_9", modernIcon: ModernIcon(digit: 9)(.circle))
    static let number0 = CommandImage(name: "NUMBER_0", modernIcon: ModernIcon(digit: 0)(.circle))
    
    static let pause = CommandImage(name: "PAUSE", modernIcon: .pause)
    static let play = CommandImage(name: "PLAY", modernIcon: .play)
    static let record = CommandImage(name: "RECORD", modernIcon: .record)
    static let `repeat` = CommandImage(name: "REPEAT", modernIcon: .repeat)
    static let rewind = CommandImage(name: "REW", modernIcon: .backward)
    static let start = CommandImage(name: "START", modernIcon: ModernIcon.backward(.end))
    static let stop = CommandImage(name: "STOP", modernIcon: .stop)
    
    static let up = CommandImage(name: "UP", modernIcon: ModernIcon.chevron(.up)(.circle))
    static let down = CommandImage(name: "DOWN", modernIcon: ModernIcon.chevron(.down)(.circle))
    static let left = CommandImage(name: "LEFT", modernIcon: ModernIcon.chevron(.left)(.circle))
    static let right = CommandImage(name: "RIGHT", modernIcon: ModernIcon.chevron(.right)(.circle))
}
