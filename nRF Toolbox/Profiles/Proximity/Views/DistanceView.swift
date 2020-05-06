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
