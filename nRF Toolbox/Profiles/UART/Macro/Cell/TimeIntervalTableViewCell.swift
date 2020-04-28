//
//  TimeIntervalTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class TimeIntervalTableViewCell: UITableViewCell {
    
    @IBOutlet private var stepper: UIStepper!
    @IBOutlet private var label: UILabel!
    
    var callback: ((UARTMacroTimeInterval, Int) -> ())!
    private var index: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func changedTimeInterval(_ sender: UIStepper) {
        let value = Int(sender.value)
        label.text = "\(value) ms"
        let ti = UARTMacroTimeInterval(milliseconds: value)
        callback(ti, index)
    }
    
    func apply(timeInterval: UARTMacroTimeInterval, index: Int) {
        let ti = timeInterval.milliseconds
        self.index = index 
        stepper.value = Double(ti)
        label.text = "\(ti) ms"
    }
}
