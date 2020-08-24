//
//  UARTPreset+View.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIImage {

    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { ctx in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func drawInColor(color: UIColor) -> UIImage {
        return UIGraphicsImageRenderer(size: self.size).image { (ctx) in
            color.setFill()
            ctx.cgContext.clip(to: CGRect(origin: .zero, size: self.size), mask: self.cgImage!)
            ctx.cgContext.fill(CGRect(origin: .zero, size: self.size))
        }
    }

}


extension UARTPreset {
    func renderImage(size: CGSize, spacing: CGFloat = 4) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { (ctx) in
            let context = ctx.cgContext
            
            let minSide = min(size.width, size.height)
            
            let dh = (size.height - minSide) / 2
            let dw = (size.width - minSide) / 2
            
            let iconSize = (minSide - 4 * spacing) / 3
            
            context.concatenate(CGAffineTransform(scaleX: 1, y: -1))
            context.concatenate(CGAffineTransform(translationX: 0, y: -size.height))
            
            for i in 0..<3 {
                for j in 0..<3 {
                    let commandIndex = i * 3 + j
                    let command = self.commands[commandIndex]
                    guard !(command is EmptyModel), let img = command.image else { continue }
                    
                    let color: UIColor = UIColor.nordicBlue
                    guard let newImage = img
                        .resize(targetSize: CGSize(width: iconSize, height: iconSize))
                        .drawInColor(color: color)
                        .drawInColor(color: color) // TODO: that is workeround to fix coordinates problem
                        .cgImage else {
                        continue
                    }
                    
                    let x = CGFloat(j) * (iconSize + spacing) + spacing + dw
                    let y = size.height - dh - iconSize - (CGFloat(i) * (iconSize + spacing) + spacing)
                    context.draw(newImage, in: CGRect(x: x, y: y, width: iconSize, height: iconSize))
                }
            }
        }
        
        return image
    }
}
