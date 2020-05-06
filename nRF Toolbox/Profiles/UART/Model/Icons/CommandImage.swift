/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
            return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
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
        name = value
        systemIcon = nil
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
