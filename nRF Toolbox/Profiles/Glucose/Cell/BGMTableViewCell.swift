//
//  BGMTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 11/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class BGMTableViewCell: UITableViewCell {

    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var placeLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
    
    func update(with reading: GlucoseReading) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        dateLabel.text = dateFormatter.string(from: reading.timestamp as Date)
        
        if reading.glucoseConcentrationTypeAndLocationPresent {
            placeLabel.text = "\(reading.type!)"

            switch reading.unit! {
            case .mol_L:
                valueLabel.text = String(format: "%.1f", reading.glucoseConcentration! * 1000)   // mol/l -> mmol/l conversion
                unitLabel.text = "mmol/l"
                break
            case .kg_L:
                valueLabel.text = String(format: "%0f", reading.glucoseConcentration! * 100000)  // kg/l -> mg/dl conversion
                unitLabel.text = "mg/dl"
                break
            }
        } else {
            valueLabel.text = "-"
            placeLabel.text = "Unavailable"
            unitLabel.text = ""
        }
    }
    
}
