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

open class SegmentedView: UIView {
    
    @IBInspectable
    open var separatorColor: UIColor = {
        if #available(iOS 13, *) {
            return .separator
        } else {
            return .gray
        }
    }()
    
    @IBInspectable
    open var separatorWidth: CGFloat = 0.5
    
    open var segments: [Segment] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard segments.count > 0 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let filledAreaWidth = rect.width - CGFloat(segments.count - 1) * separatorWidth
        let totalSize = segments.reduce(0) { $0 + $1.size }
        
        var phase = CGFloat(0)
        
        context.setFillColor(separatorColor.cgColor)
        context.addRect(rect)
        context.drawPath(using: .fill)
        
        for segment in segments {
            let segmentWidth = filledAreaWidth * CGFloat(segment.size / totalSize)
            context.setFillColor(segment.color.cgColor)
            let segmentRect = CGRect(x: phase, y: 0, width: segmentWidth, height: rect.height)
            context.addRect(segmentRect)
            context.drawPath(using: .fill)
            phase += (segmentWidth + separatorWidth)
        }
        
    }
}
