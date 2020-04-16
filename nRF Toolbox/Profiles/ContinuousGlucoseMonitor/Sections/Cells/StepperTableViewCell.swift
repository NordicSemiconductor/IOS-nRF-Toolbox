//
//  SliderTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct StepperCellModel {
    let min, max: Double
    let step: Double
    var value: Double
}

class StepperTableViewCell: UITableViewCell {

    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    
    var timeIntervalChanges: ( (Int) -> () )!
    
    func update(with model: StepperCellModel) {
        stepper.minimumValue = model.min
        stepper.maximumValue = model.max
        stepper.value = model.value
        stepper.stepValue = model.step
        valueLabel.text = "\(Int(model.value)) min"
    }
    
    @IBAction private func valueChanged(sender: UIStepper) {
        let newValue = Int(sender.value)
        timeIntervalChanges(newValue)
        valueLabel.text = "\(Int(sender.value)) min"
    }
}
