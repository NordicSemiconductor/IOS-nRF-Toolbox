//
//  DistanceView.swift
//  DistantChart
//
//  Created by Nick Kibish on 16.04.2020.
//  Copyright © 2020 MyEzJob. All rights reserved.
//

import UIKit

extension UIColor {
    func getRGBA() -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
    
    func secordary() -> UIColor {
        var (red, green, blue, alpha) = getRGBA()
        var k: CGFloat = 0.75
        if #available(iOS 13, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                k = 1.25
            }
        }
        
        red *= k
        blue *= k
        green *= k
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        
    }
}

class DistanceView: UIView {
    private struct Constants {
        static let numberOfGlasses = 8
        static let lineWidth: CGFloat = 5.0
        static let arcWidth: CGFloat = 24
        static let borderWidth: CGFloat = 2
        
        static var halfOfLineWidth: CGFloat {
            return lineWidth / 2
        }
    }
    
    @IBInspectable var counter: Int = 5 {
        didSet {
            if counter <=  Constants.numberOfGlasses {
                //the view needs to be refreshed
                setNeedsDisplay()
            }
        }
    }
    @IBInspectable var outlineColor: UIColor = UIColor.blue
    @IBInspectable var counterColor: UIColor = UIColor.orange
    
    private var shadowPath: UIBezierPath!
    
    var startDrawingAngle: CGFloat = CGFloat.pi / 10
    var numberOfSectors: Int = 9
    var unfilledSectors: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var spaceAngle: CGFloat = CGFloat.pi / 100
    
    lazy var colorForInder: (Int) -> (UIColor) = { [weak self] i -> UIColor in
        guard let `self` = self else { return .clear }
        
        if i > self.numberOfSectors - self.unfilledSectors {
            return .nordicGrey4
        }
        switch i {
        case (..<3): return .nordicRed
        case 3..<6: return .nordicFall
        case (6...): return .nordicGreen
        default: return .nordicGrey4
        }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
        let radius: CGFloat = max(bounds.width, bounds.height) - 8
        
        let segmentAngle = (CGFloat.pi - startDrawingAngle) / CGFloat(numberOfSectors) - spaceAngle
        
        let entireAngle = CGFloat(numberOfSectors) * (segmentAngle + spaceAngle)
        let drawStartAngle = CGFloat.pi - entireAngle
        
        shadowPath = UIBezierPath()
        
        for n in 0..<numberOfSectors {
            let startAngle: CGFloat = CGFloat(n) * (segmentAngle + spaceAngle) + drawStartAngle + spaceAngle / 2
            let delta = CGFloat.pi / 2
            
            let endAngle: CGFloat = startAngle + segmentAngle
            drawArc(startAngle: startAngle + delta,
                    endAngle: endAngle + delta,
                    clockwise: true,
                    index: n, radius: radius/2 - Constants.arcWidth/2)
            
            drawArc(startAngle: -startAngle + delta,
                    endAngle: -endAngle + delta,
                    clockwise: false,
                    index: n, radius: radius/2 - Constants.arcWidth/2)
        }
        
        layer.shadowPath = shadowPath.cgPath
        layer.shadowColor = UIColor.blue.cgColor
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5
        
    }
    
    func drawArc(startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool, index: Int, radius: CGFloat) {
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        let color = colorForInder(index)
        
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: clockwise)
        
        
        path.lineWidth = Constants.arcWidth
        color.setStroke()
        path.stroke()

        let borderPath = UIBezierPath(arcCenter: center,
                                      radius: radius - Constants.arcWidth / 2,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: clockwise)
        borderPath.addArc(withCenter: center,
                          radius: radius + Constants.arcWidth / 2,
                          startAngle: endAngle,
                          endAngle: startAngle,
                          clockwise: !clockwise)
        
        borderPath.close()
        
        
        borderPath.lineWidth = 2
        color.secordary().setStroke()
        borderPath.stroke()
    }
    
}
