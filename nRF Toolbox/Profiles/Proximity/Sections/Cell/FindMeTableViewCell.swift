//
//  FindMeTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class FindMeTableViewCell: UITableViewCell {
    @IBOutlet var findMeBtn: UIButton?
    @IBOutlet var signalImage: UIImageView!
    @IBOutlet var bgSignalImage: UIImageView!
    
    var action: (() -> ())!
    
    func update(with rssi: Int?, tx: Int?, title: String) {
        findMeBtn?.layer.borderWidth = 1.5
        findMeBtn?.layer.cornerRadius = 4

        bgSignalImage.image = UIImage(named: "signal-level3")?.withRenderingMode(.alwaysTemplate)
        findMeBtn?.setTitle(title, for: .normal)

        if #available(iOS 13.0, *) {

            signalImage.tintColor = .systemGray2

            switch rssi {
            case let r? where r < -90:
                bgSignalImage.tintColor = .systemRed
                signalImage.image = UIImage(named: "signal-level0")?.withRenderingMode(.alwaysTemplate)
            case let r? where r < -70:
                bgSignalImage.tintColor = .systemOrange
                signalImage.image = UIImage(named: "signal-level1")?.withRenderingMode(.alwaysTemplate)
            case let r? where r < -50:
                bgSignalImage.tintColor = .systemYellow
                signalImage.image = UIImage(named: "signal-level2")?.withRenderingMode(.alwaysTemplate)
            default:
                signalImage.image = UIImage(named: "signal-level3")?.withRenderingMode(.alwaysTemplate)
                signalImage.tintColor = .systemGreen
            }

            findMeBtn?.layer.borderColor = UIColor.systemGray3.cgColor
            findMeBtn?.setTitleColor(.secondaryLabel, for: .normal)
        }

        if let tx = tx, let rssi = rssi {
            let distance = self.distance(rssi: rssi, tx: tx)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .naturalScale
        }
    }
    
    @IBAction func buttonTapped() {
        action()
    }

    private func distance(rssi: Int, tx: Int) -> Measurement<UnitLength> {
        let d = pow(10, (Double(tx - rssi) / 20.0))
        return Measurement<UnitLength>(value: d, unit: .millimeters)
    }
}
