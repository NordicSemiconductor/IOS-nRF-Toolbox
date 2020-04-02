//
//  NordicRightDetailTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NordicRightDetailTableViewCell: UITableViewCell {
    
    override var tintColor: UIColor! {
        didSet {
            textLabel?.textColor = tintColor
            detailTextLabel?.textColor = tintColor
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        let tlFontSize = textLabel?.font.pointSize ?? 12
        let dlFontSize = detailTextLabel?.font.pointSize ?? 12
        
        textLabel?.font = UIFont.gtEestiDisplay(.regular, size: tlFontSize)
        detailTextLabel?.font = UIFont.gtEestiDisplay(.regular, size: dlFontSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
