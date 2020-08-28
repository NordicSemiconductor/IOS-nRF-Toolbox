//
// Created by Nick Kibysh on 27/08/2020.
// Copyright (c) 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

class TextCommandCoder: NSObject, CommandCoding {
    private struct Key {
        static let text = "TextCommandCoder.Key.text"
        static let eol = "TextCommandCoder.Key.eol"
        static let icon = "TextCommandCoder.Key.icon"
    }

    var command: Command { textCommand }
    var textCommand: TextCommand

    init(textCommand: TextCommand) {
        self.textCommand = textCommand
        super.init()
    }

    required init?(coder: NSCoder) {
        guard let text = coder.decodeObject(forKey: Key.text) as? String,
              let eol = (coder.decodeObject(forKey: Key.eol) as? String).flatMap({ EOL(rawValue: $0) }),
              let icon = coder.decodeObject(forKey: Key.icon) as? CommandImageCoder else {
            return nil
        }

        self.textCommand = TextCommand(text: text, image: icon.icon, eol: eol)
    }

    func encode(with coder: NSCoder) {
        coder.encode(textCommand.title, forKey: Key.text)
        coder.encode(CommandImageCoder(icon: textCommand.icon), forKey: Key.icon)
        coder.encode(textCommand.eol.rawValue, forKey: Key.eol)
    }

    
}
