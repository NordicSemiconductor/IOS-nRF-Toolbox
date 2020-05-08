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
    
    static func instanceWithParams(message: String? = nil, image: UIImage? = nil, buttonSettings: ButtonSettings? = nil) -> InfoActionView {
        let view = InfoActionView.instance()
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
