//
//  UARTIncrementViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTIncrementViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet var stepper: UIStepper!

    var stepperSetup: (min: Int, max: Int, val: Int, step: Int) = (0, 100, 1, 1) {
        didSet {
            stepper.minimumValue = Double(stepperSetup.min)
            stepper.maximumValue = Double(stepperSetup.max)
            stepper.value = Double(stepperSetup.val)
            stepper.stepValue = Double(stepperSetup.step)
        }
    }

    var stepperValueChanged: ((Int) -> ())!

    init() {
        super.init(nibName: "UARTIncrementViewController", bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stepper.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @IBAction func valueChanged(_ stepper: UIStepper) {
        stepperValueChanged?(Int(stepper.value))
    }
}
