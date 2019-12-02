//
//  ProgressImageView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/11/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ProgressImageView: UIView {
    @IBInspectable
    var image: UIImage? {
        didSet {
            redraw()
        }
    }
    
    var progress: Float = 0 {
        didSet {
            redraw()
        }
    }
    
    init(image: UIImage?) {
        super.init(frame: .zero)
        self.image = image
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        redraw()
    }
    
    private func redraw() {
        self.layer.sublayers?.removeAll()
        
        guard let image = self.image else {
            return
        }
        
        let mask = CALayer()
        mask.contents = image.cgImage!
        mask.frame = self.bounds
        
        let gradient = CAGradientLayer()
        let colors: [UIColor] = [.systemGray, .systemBlue]
        gradient.colors = colors.map { $0.cgColor }
        gradient.frame = self.bounds
        
        let p = NSNumber(value: 1 - self.progress)
        gradient.locations = [p, p]
        
        gradient.masksToBounds = true
        gradient.mask = mask
        
        self.layer.addSublayer(gradient)
    }
}

