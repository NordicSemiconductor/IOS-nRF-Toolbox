//
//  LegendLabel.swift
//  SegmentedView
//
//  Created by Nick Kibysh on 28/02/2020.
//

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
            self.text = segment?.shortTitle ?? segment?.title
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
        
        guard let segment = self.segment else {
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
