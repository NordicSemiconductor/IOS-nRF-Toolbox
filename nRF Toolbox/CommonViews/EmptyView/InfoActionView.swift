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
