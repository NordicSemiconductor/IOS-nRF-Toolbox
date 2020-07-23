//
//  ActionHeaderView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 23/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ActionHeaderView: UIView, XibInstantiable {
    var editButtonCallback: (() -> ())?
    var title: String? {
        didSet {
            titleLabel.text = title 
        }
    }
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var editButton: UIButton!
    
    @IBAction private func editBtnPressed() {
        editButtonCallback?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        editButton.contentHorizontalAlignment = .fill
        editButton.contentVerticalAlignment = .fill
    }
}
