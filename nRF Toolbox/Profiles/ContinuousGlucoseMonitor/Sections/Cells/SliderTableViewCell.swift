//
//  SliderTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct SliderCellModel {
    let title: String

    let min, max: Double
    let step: Double
    var value: Double
}

class SliderTableViewCell: UITableViewCell {

    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    
    var timeIntervalChanges: ( (Int) -> () )!
    
    func update(with model: SliderCellModel) {
        stepper.minimumValue = model.min
        stepper.maximumValue = model.max
        stepper.value = model.value
        valueLabel.text = "\(model.value) min"
    }
    
    @IBAction private func valueChanged(sender: UIStepper) {
        let newValue = Int(sender.value)
        timeIntervalChanges(newValue)
        valueLabel.text = "\(Int(sender.value)) min"
    }

    func textToImage(drawText text: String) -> UIImage {
        var textColor = UIColor.white

        if #available(iOS 13, *) {
            textColor = .label
        }

        let textFont = UIFont(name: "Helvetica Bold", size: 12)!

        let scale = UIScreen.main.scale
        let textFontAttributes = [
            .font: textFont,
            .foregroundColor: textColor,
        ] as [NSAttributedString.Key : Any]

        let attributedString = NSAttributedString(string: text, attributes: textFontAttributes)

        let width = attributedString.width(withConstrainedHeight: .greatestFiniteMagnitude)
        let height = attributedString.height(withConstrainedWidth: .greatestFiniteMagnitude)
        let size = CGSize(width: width, height: height)
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContext(size)

        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.width)
    }
}
