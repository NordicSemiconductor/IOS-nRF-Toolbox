//
//  NordicTextTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol NordicTextTableViewCellModel {
    var image: UIImage? { get }
    var text: String? { get }
}

class NordicTextTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupAppearance() {
        let defaultSize = textLabel?.font.pointSize ?? 12
        textLabel?.font = UIFont.gtEestiDisplay(.regular, size: defaultSize)
    }
    
    func apply(_ model: NordicTextTableViewCellModel) {
        textLabel?.text = model.text
        imageView?.image = model.image
    }
}
