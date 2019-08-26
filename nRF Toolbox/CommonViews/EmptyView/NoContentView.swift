//
//  NoContentView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NoContentView: UIView, XibInstantiable {
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var actionButton: UIButton!
    @IBOutlet private var imageView: UIImageView!
    
    var message: String? {
        didSet {
            self.messageLabel.text = message
            self.messageLabel.isHidden = message == nil
        }
    }
    
    var image: UIImage? {
        didSet {
            self.imageView.image = image
            self.imageView.isHidden = image == nil
        }
    }
    
    private var action: Action?
    var buttonSettings: ButtonSettings? {
        didSet {
            self.actionButton.isHidden = buttonSettings == nil
            self.actionButton.setTitle(buttonSettings?.0, for: .normal)
            self.action = buttonSettings?.1
        }
    }
    
    typealias Action = (() -> Void)
    typealias ButtonSettings = (String, Action)
    
    @IBAction private func executeAction(_ sender: UIButton) {
        action?()
    }
    
    static func instanceWithParams(message: String? = nil, image: UIImage? = nil, buttonSettings: ButtonSettings? = nil) -> NoContentView {
        let view = NoContentView.instance()
        view.messageLabel.text = message
        view.imageView.image = image
        view.buttonSettings = buttonSettings
        
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.actionButton.layer.borderColor = UIColor.tableViewSeparator.cgColor
        self.actionButton.layer.borderWidth = 2
        self.actionButton.layer.cornerRadius = 2
        self.actionButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }
}
