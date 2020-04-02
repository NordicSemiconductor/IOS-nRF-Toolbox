//
//  SegmentedView.swift
//  Pods-SegmentedView_Example
//
//  Created by Nick Kibysh on 28/02/2020.
//

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
