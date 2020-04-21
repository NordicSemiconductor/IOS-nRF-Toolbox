//
//  SignalStrengthView.swift
//  DistantChart
//
//  Created by Nick Kibish on 19.04.2020.
//  Copyright © 2020 MyEzJob. All rights reserved.
//

import UIKit

class SignalStrengthView: UIView {
    
    var numberOfBars: Int = 4
    var filledBars: Int = 3 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var x0: Double = 0.5
    var x1: Double = 2
    
    var foo: (Double) -> Double = { $0 * $0 }
    
    var spacing: CGFloat = 3
    
    var color: ((Int, Int) -> UIColor)! = { (filledBars, total) -> UIColor in
        let k = Double(filledBars) / Double(total)
        
        switch k {
        case .leastNonzeroMagnitude...0.25: return .nordicRed
        case 0.25...0.5: return .nordicFall
        case 0.5...0.75: return .nordicYello
        case 0.75...1: return .nordicGreen
        default:
            return .nordicDarkGray
        }
    }

    override func draw(_ rect: CGRect) {
        let firstBarHeight: CGFloat = rect.height / 100
        
        layer.masksToBounds = false
        
        let ppi = foo(x1) / Double(rect.height - firstBarHeight)
        
        let delta = (x1 - x0) / Double(numberOfBars)
        let barWidth = (rect.width - spacing * CGFloat(numberOfBars - 1)) / CGFloat(numberOfBars)
        var startPoint = CGFloat(0)
        let color = self.color(filledBars, numberOfBars)
        
        sequence(first: x0) { [x1] (x) -> Double? in
            let next = x + delta
            return next <= x1 ? next : nil
        }
        .enumerated()
        .forEach {
            
            let height = CGFloat(self.foo($0.element)) / CGFloat(ppi) + firstBarHeight
            let barRect = CGRect(x: startPoint, y: rect.height - height, width: barWidth, height: height)
            let path = UIBezierPath(roundedRect: barRect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 2, height: 2))
            
            if $0.offset < self.filledBars {
                color.setFill()
                path.fill()
            } else {
                color.setStroke()
                path.stroke()
            }
            
            startPoint += spacing + barWidth
        }
        
        
    }

}
