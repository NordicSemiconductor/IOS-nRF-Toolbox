//
//  ArgumentLabel.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ArgumentLabel: UILabel {
    private let edgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    
    var labelDidPressed: ((ArgumentLabel) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var isHighlighted: Bool {
        didSet {
            let blue = UIColor.nordicLake
            backgroundColor = isHighlighted ? blue.adjustAlpha(0.7) : blue.adjustAlpha(0.2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        isHighlighted.toggle()
        
        labelDidPressed?(self)
    }
    
    open override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgeInsets))
    }
    
    open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var newBounds = bounds
        newBounds = bounds.inset(by: edgeInsets)
        var textRect = super.textRect(forBounds: newBounds, limitedToNumberOfLines: numberOfLines)
        textRect.size.width += edgeInsets.left + edgeInsets.right
        textRect.origin.x = 8
        return textRect
    }
}
