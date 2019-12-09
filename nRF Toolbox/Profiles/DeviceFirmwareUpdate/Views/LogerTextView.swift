//
//  LogerTextView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 05/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class LogerTextView: UITextView, LoggerDelegate {
    func logWith(_ level: LogLevel, message: String) {
        let color: UIColor = {
            switch level {
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
        }()

        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor : color]
        let newText = NSAttributedString(string: "\(message)\n", attributes: attributes)
        let attributedText = NSMutableAttributedString(attributedString: self.attributedText)
        attributedText.append(newText)
        self.attributedText = attributedText
        
        self.contentOffset = CGPoint(x: 0, y: max(0, (contentSize.height - frame.height)))
    }
}
