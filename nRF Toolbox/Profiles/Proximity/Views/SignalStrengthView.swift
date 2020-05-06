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
        case 0.5...0.75: return .nordicYellow
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
