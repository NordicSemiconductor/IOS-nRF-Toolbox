//
//  ProgressView.swift
//  NordicProgressView
//
//  Created by Nick Kibysh on 27/11/2019.
//  Copyright © 2019 Nick Kibysh. All rights reserved.
//

import UIKit

private extension CGSize {
    static func scaleIndex(viewSize: CGSize, layerSize: CGSize) -> CGFloat {
        let heightIndex = viewSize.height / layerSize.height
        let widthIndex = viewSize.width / layerSize.width
        return min(heightIndex, widthIndex)
    }
    
    static func shift(viewSize: CGSize, layerSize: CGSize) -> CGPoint {
        let dx = (viewSize.width - layerSize.width) / 2
        let dy = (viewSize.height - layerSize.height) / 2
        return CGPoint(x: dx, y: dy)
    }
}

struct ProgressPart {
    let parts: Int
    let color: UIColor
    
    static let `default` = ProgressPart(parts: 1, color: .nordicBlue)
    static let error = ProgressPart(parts: 1, color: .nordicRed)
    static let done = ProgressPart(parts: 1, color: .nordicGreen)
}

struct ProgressImageConfigurator {
    var progressParts: [ProgressPart] = [.default]
    var image: UIImage
    var progress: Int
    
    static let file = ProgressImageConfigurator(image: UIImage(named: "ic_document")!, progress: 0)
    static let device = ProgressImageConfigurator(image: UIImage(named: "chip_ic")!, progress: 0)
    static let error = ProgressImageConfigurator(progressParts: [.error], image: UIImage(named: "error_alert")!, progress: 0)
    static let done = ProgressImageConfigurator(progressParts: [.done], image: UIImage(named: "done_ic")!, progress: 0)
}

class ProgressImage: UIView {
    @IBInspectable
    var image: UIImage? {
        didSet { redraw() }
    }
    
    var parts: [ProgressPart] = [] {
        didSet { redraw() }
    }
    
    var progress: Int = 0 {
        didSet { redraw() }
    }
    
    var inactiveColor: UIColor = .nordicAlmostWhite {
        didSet { redraw() }
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        redraw()
    }
    
    func apply(configurator: ProgressImageConfigurator) {
        self.image = configurator.image
        self.progress = configurator.progress
        self.parts = configurator.progressParts
    }
    
    private func redraw() {
        self.layer.sublayers?.removeAll()
        
        guard let image = self.image else {
            return
        }
        
        let imageSize = image.size
        var frame = CGRect.zero
        frame.size = imageSize
        
        let index = CGSize.scaleIndex(viewSize: self.frame.size, layerSize: imageSize)
        let scaleTransform = CGAffineTransform(scaleX: index, y: index)
        
        let shiftPoint = CGSize.shift(viewSize: self.frame.size, layerSize: imageSize)
        let shiftTransform = CGAffineTransform(translationX: shiftPoint.x, y: shiftPoint.y)
        
        let t = scaleTransform.concatenating(shiftTransform)
        
        let mask = CALayer()
        mask.contents = image.cgImage!
        mask.frame = frame
        mask.transform = CATransform3DMakeAffineTransform(t)
        
        let gradient = CAGradientLayer()
        var locations: [Float] = colorPositions(parts)
        var colors: [UIColor] = partsColors(parts)
        
        if progress > 0 {
            let updated = updateGradient(with: progress, positions: locations, colors: colors)
            locations = updated.0
            colors = updated.1
        }
        
        gradient.colors = colors.map { $0.cgColor }
        gradient.frame = self.bounds
        
        gradient.locations = locations.map { NSNumber(value: $0) }
        
        gradient.masksToBounds = true
        gradient.mask = mask
        
        self.layer.addSublayer(gradient)
    }
    
    private func partsColors(_ parts: [ProgressPart]) -> [UIColor] {
        parts.map { $0.color }.reduce([UIColor](), { $0 + [$1, $1] })
    }
    
    private func colorPositions(_ parts: [ProgressPart]) -> [Float] {
        let totalCount = parts.reduce(0, { $0 + $1.parts })
        return parts.reduce([Float]()) { (r, position) in
            let percent = Float(position.parts) / Float(totalCount)
            let last = r.last ?? 0
            return r + [last, last + percent]
        } + [1.0]
    }
    
    private func updateGradient(with progress: Int, positions: [Float], colors: [UIColor]) -> ([Float], [UIColor]) {
        let percentProgress = Float(progress) / 100
        
        let filteredPositions = positions.filter { $0 > percentProgress }
        let diff = ((colors.count - filteredPositions.count) / 2) * 2
        let newColors =  [inactiveColor, inactiveColor] + colors.dropFirst(diff)
        let newPositions = [0, percentProgress, percentProgress] + filteredPositions
        
        return (newPositions, newColors)
    }
}
