//
//  DFUUpdateProgressView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 11/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUUpdateProgressView: UIView, XibInstantiable {
    
    enum Style {
        case update, error, done
    }
    
    @IBOutlet var updateLogoImage: UIImageView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    
    var style: Style = .update {
        didSet {
            let colorImage: (UIColor, ModernIcon, UIImage?) = {
                let oldImage = UIImage(named: "FeatureDFU")?.withRenderingMode(.alwaysTemplate)
                switch style {
                case .done: return (.nordicGreen, ModernIcon.checkmark(.circle), oldImage)
                case .error: return (.nordicRed, ModernIcon.exclamationmark(.triangle), oldImage)
                case .update: return (.nordicBlue, ModernIcon.arrow(.init(digit: 2))(.circlePath), oldImage)
                }
            }()
            
            updateLogoImage.tintColor = colorImage.0
            if #available(iOS 13, *) {
                updateLogoImage.image = colorImage.1.image
            } else {
                updateLogoImage.image = colorImage.2
            }
            
            progressView.tintColor = colorImage.0
            statusLabel.textColor = style == .error ? .nordicRed : UIColor.Text.secondarySystemText
            
            if style != .update {
                stopAnimating()
            }
        }
    }
    
    func startAnimating() {
        updateLogoImage.translatesAutoresizingMaskIntoConstraints = true
        
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: [.repeat], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                if #available(iOS 13, *) {
                    self.updateLogoImage.transform = CGAffineTransform(rotationAngle: .pi)
                }
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.updateLogoImage.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.updateLogoImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        })
    }
    
    func stopAnimating() {
        updateLogoImage.layer.removeAllAnimations()
    }
    
}
