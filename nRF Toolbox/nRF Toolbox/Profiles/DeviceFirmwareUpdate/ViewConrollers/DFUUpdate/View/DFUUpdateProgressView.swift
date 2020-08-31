/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/


import Core
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
                let oldImage = UIImage(named: "update_ic")?.withRenderingMode(.alwaysTemplate)
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
//        updateLogoImage.translatesAutoresizingMaskIntoConstraints = true
        
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: [.repeat], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                self.updateLogoImage.transform = CGAffineTransform(rotationAngle: .pi)
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
