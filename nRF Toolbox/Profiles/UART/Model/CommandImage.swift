//
//  CommandImage.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIImage

struct CommandImage: Codable {
    var name: String
    var image: UIImage? { UIImage(named: self.name) }
    
    init(name: String) {
        self.name = name
    }
}

extension CommandImage: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.name = value
    }
}

extension CommandImage: CaseIterable {
    static let allCases: [CommandImage] = [.pause, .play, .record, .repeat, .rewind, .start, .stop, .number1, .number2, .number3, .number4, .number5, .number6, .number7, .number8, .number9]
}

extension CommandImage {
    static let empty: CommandImage = ""
    static let number1: CommandImage = "NUMBER_1"
    static let number2: CommandImage = "NUMBER_2"
    static let number3: CommandImage = "NUMBER_3"
    static let number4: CommandImage = "NUMBER_4"
    static let number5: CommandImage = "NUMBER_5"
    static let number6: CommandImage = "NUMBER_6"
    static let number7: CommandImage = "NUMBER_7"
    static let number8: CommandImage = "NUMBER_8"
    static let number9: CommandImage = "NUMBER_9"
    
    static let pause: CommandImage = "PAUSE"
    static let play: CommandImage = "PLAY"
    static let record: CommandImage = "RECORD"
    static let `repeat`: CommandImage = "REPEAT"
    static let rewind: CommandImage = "REW"
    static let start: CommandImage = "START"
    static let stop: CommandImage = "STOP"
}


