//
//  UARTActionCollectionViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 13.01.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTActionCollectionViewCell: UICollectionViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var image: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func apply(command: UARTCommandModel) {
        title.text = command.title
        image.image = command.image.image
        title.textColor = {
            if command is DataCommand {
                return UIColor.Text.secondarySystemText
            } else {
                return UIColor.Text.systemText
            }
        }()
    }
}
