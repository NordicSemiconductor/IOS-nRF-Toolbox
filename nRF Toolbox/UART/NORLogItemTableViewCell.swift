//
//  NORLogItemTableViewCell.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORLogItemTableViewCell: UITableViewCell {
    //MARK: - Properties
    var logItem : NORLogItem?

    //MARK: - Cell Outlets

    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var message: UILabel!
    
    //MARK: - Implementation
    func setItem(item anItem : NORLogItem){
        logItem = anItem

        timestamp.text = anItem.timestamp;
        message.text = anItem.message;
        
        // Use the color based on the log level
        var color : UIColor?
        switch (anItem.level!) {
            case .debugLogLevel:
                color = UIColor(red:0x00/255.0, green:0x9C/255.0, blue:0xDE/255.0, alpha:1.0)
                break
                
            case .verboseLogLevel:
                color = UIColor(red:0xB8/255.0, green:0xB0/255.0, blue:0x56/255.0, alpha:1.0)
                break
                
            case .infoLogLevel:
                color = UIColor.black
                break
                
            case .appLogLevel:
                color = UIColor(red:0x23/255.0, green:0x8C/255.0, blue:0x0F/255.0, alpha:1.0)
                break
                
            case .warningLogLevel:
                color = UIColor(red:0xD7/255.0, green:0x79/255.0, blue:0x26/255.0, alpha:1.0)
                break
                
            case .errorLogLevel:
                color = UIColor.red
                break
        }

        self.message.textColor = color
    }
}
