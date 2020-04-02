//
//  InfoActionView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class InfoActionView: UIView, XibInstantiable {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var actionButton: NordicButton!
    @IBOutlet var imageView: UIImageView!
    
    var message: String? {
        didSet {
            titleLabel.text = message
            titleLabel.isHidden = message == nil
        }
    }
    
    var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = image == nil
        }
    }
    
    var action: Action?
    var buttonSettings: ButtonSettings? {
        didSet {
            actionButton.isHidden = buttonSettings == nil
            actionButton.setTitle(buttonSettings?.0, for: .normal)
            action = buttonSettings?.1
        }
    }
    
    typealias Action = (() -> Void)
    typealias ButtonSettings = (String, Action)
    
    @IBAction func executeAction(_ sender: UIButton) {
        action?()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func instanceWithParams(message: String? = nil, image: UIImage? = nil, buttonSettings: ButtonSettings? = nil) -> InfoActionView {
        let view = InfoActionView.instance()
        view.titleLabel.text = message
        view.imageView.image = image
        view.buttonSettings = buttonSettings
        
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
            imageView.tintColor = .systemGray3
        }
    }
}
