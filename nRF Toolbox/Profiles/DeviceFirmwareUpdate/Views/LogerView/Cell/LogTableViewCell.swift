//
//  LogTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class LogTableViewCell: UITableViewCell {
    
    @IBOutlet private var message: UILabel!
    @IBOutlet private var time: UILabel!
    
    func update(with log: LogMessage) {
        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor : log.level.color]
        let text = NSAttributedString(string: log.message, attributes: attributes)
        message.attributedText = text
        time.text = DateFormatter.longTimeFormatter.string(from: log.time)
    }
    
}
