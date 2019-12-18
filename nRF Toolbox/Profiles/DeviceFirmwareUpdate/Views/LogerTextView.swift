//
//  LogerTextView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 05/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

extension LogLevel {
    var color: UIColor {
        switch self {
        case .warning: return .nordicFall
        case .error: return .nordicRed
        case .application: return .nordicGreen
        case .info: return .nordicBlue
        case .verbose: return .nordicLake
        default:
            if #available(iOS 13, *) {
                return .label
            } else {
                return .black
            }
        }
    }
}

class LogerTextView: UITextView, LoggerDelegate {
    func scrollToBottom() {
        if text.count > 0 {
            let location = text.count - 1
            let bottom = NSMakeRange(location, 1)
            scrollRangeToVisible(bottom)
        }
    }
    
    func logWith(_ level: LogLevel, message: String) {
        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor : level.color]
        let newText = NSAttributedString(string: "\(message)\n", attributes: attributes)
        let attributedText = NSMutableAttributedString(attributedString: self.attributedText)
        attributedText.append(newText)
        self.attributedText = attributedText
        scrollToBottom()
    }
}
