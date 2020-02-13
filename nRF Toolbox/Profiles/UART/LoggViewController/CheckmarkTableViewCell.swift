//
//  CheckmarkTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class CheckmarkTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        imageView?.tintColor = .nordicBlue
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        imageView?.tintColor = .nordicBlue
        selectionStyle = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let image = (selected ? selectedImg : img)?.withRenderingMode(.alwaysTemplate)
        imageView?.image = image
    }
    
    private let img: UIImage? = {
        if #available(iOS 13, *) {
            return ModernIcon.circle.image
        } else {
            return UIImage(named: "circle")
        }
    }()
    
    private let selectedImg: UIImage? = {
        if #available(iOS 13, *) {
            return ModernIcon.checkmark(.circle)(.fill).image
        } else {
            return UIImage(named: "baseline_check_circle_white_36pt")?.withRenderingMode(.alwaysTemplate)
        }
    }()
    

}
