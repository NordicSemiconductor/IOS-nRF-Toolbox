//
//  UIView+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIView {
    func addZeroBorderConstraints() {
        guard let superview = self.superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        [
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor)
        ].forEach { $0.isActive = true }
    }
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get { self.layer.cornerRadius }
        set { self.layer.cornerRadius = newValue }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get { layer.borderColor.flatMap { UIColor(cgColor: $0) } }
        set { layer.borderColor = newValue?.cgColor }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
}

extension UIStackView {
    func clear() {
        let subviewes = arrangedSubviews
        subviewes.forEach(removeArrangedSubview)
    }
}
