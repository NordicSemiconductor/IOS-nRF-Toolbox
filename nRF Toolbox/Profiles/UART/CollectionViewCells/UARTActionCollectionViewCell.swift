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
        
        let bgView = UIView()
        let selectedBGView = UIView()
        if #available(iOS 13.0, *) {
            bgView.backgroundColor = .systemGray5
            selectedBGView.backgroundColor = .systemGray2
        } else {
            bgView.backgroundColor = .nordicLightGray
            selectedBGView.backgroundColor = .nordicAlmostWhite
        }
        
        selectedBackgroundView = selectedBGView
        backgroundView = bgView
        
        image.tintColor = .nordicBlue
        
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }

    func apply(command: UARTCommandModel) {
        title.text = command.title
        title.textColor = {
            if command is DataCommand {
                return UIColor.Text.secondarySystemText
            } else {
                return UIColor.Text.systemText
            }
        }()
        
        image.image = command.image.image
    }
}
