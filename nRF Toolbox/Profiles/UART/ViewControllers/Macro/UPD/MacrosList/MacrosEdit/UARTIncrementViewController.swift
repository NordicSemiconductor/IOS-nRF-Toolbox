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

    var stepperSetup: (min: Int, max: Int, val: Int) = (0, 100, 1) {
        didSet {
            stepper.minimumValue = Double(stepperSetup.min)
            stepper.maximumValue = Double(stepperSetup.max)
            stepper.value = stepper.value
        }
    }

    var stepperValueChanged: ((Int) -> ())!

    init() {
        super.init(nibName: "UARTIncrementViewController", bundle: .main)

        self.popoverPresentationController?.delegate = self
        self.modalPresentationStyle = .popover
        self.preferredContentSize = CGSize(width: 110, height: 48)
        self.popoverPresentationController?.permittedArrowDirections = .up
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

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        UIModalPresentationStyle.none
    }
}
