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

class AutoReszableTextView: UITextView {
    
    //MARK: Inspectable parameters
    @IBInspectable
    var minHegiht: CGFloat = 34
    
    @IBInspectable
    var maxHegiht: CGFloat = 84
    
    var didChangeText: ((String) -> ())?
    
    private var heightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
}

//MARK: Private Methods
extension AutoReszableTextView {
    private func initialize() {
        delegate = self
        addHeightConstraint()
        backgroundColor = .nordicTextViewColor
        borderColor = .nordicTextViewBordorColor
        
        borderWidth = 1
        layer.cornerRadius = 4
    }
    
    private func addHeightConstraint() {
        heightConstraint = heightAnchor.constraint(equalToConstant: minHegiht)
        heightConstraint.isActive = true
    }
}

//MARK:
extension AutoReszableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        var size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        
        size.height = max(minHegiht, size.height)
        size.height = min(maxHegiht, size.height)
        
        heightConstraint.constant = size.height
        layoutIfNeeded()
        
        didChangeText?(textView.text)
    }
}
