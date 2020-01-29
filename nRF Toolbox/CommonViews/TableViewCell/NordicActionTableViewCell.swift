//
//  NordicActionTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NordicActionTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    private func setupAppearance() {
        let defaultSize = textLabel?.font.pointSize ?? 12
        textLabel?.font = UIFont.gtEestiDisplay(.regular, size: defaultSize)
        textLabel?.textColor = .systemBlue
    }
}
