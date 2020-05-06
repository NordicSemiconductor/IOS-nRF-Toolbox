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

open class LegendLabel: UILabel {
    private let dotRadius: CGFloat = 10
    private let leftShift: CGFloat = 20
    
    public init(segment: Segment) {
        super.init(frame: .zero)
        // Use defer to trigger didSet
        defer { self.segment = segment }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public var segment: Segment? {
        didSet {
            text = segment?.shortTitle ?? segment?.title
            layoutSubviews()
        }
    }
    
    open override func drawText(in rect: CGRect) {
        guard case .some = segment else {
            super.drawText(in: rect)
            return
        }
        var newBounds = rect
        newBounds.size.width -= leftShift
        newBounds.origin.x += leftShift
        super.drawText(in: newBounds)
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let segment = segment else {
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let dotRect = CGRect(x: (leftShift - dotRadius) / 2,
                             y: (rect.height - dotRadius) / 2,
                             width: dotRadius,
                             height: dotRadius)
        
        context.addEllipse(in: dotRect)
        context.setFillColor(segment.color.cgColor)
        context.drawPath(using: .fill)
    }
}
