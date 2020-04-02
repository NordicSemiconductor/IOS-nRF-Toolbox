//
//  DFUFirmwareSizeSchemeCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

extension DFUFirmwareSize {
    var segments: [Segment] {
        let application = Segment(size: Float(self.application), color: .nordicGreen, title: "Application", shortTitle: "App")
        
        guard bootloader + softdevice > 0 else { return [application] }
        
        if bootloader == 1 {
            let combinedSegment = Segment(size: Float(bootloader + softdevice), color: .nordicLake, title: "Soft Device + Bootloader", shortTitle: "SD+BL")
            return [combinedSegment, application]
        } else {
            let softDevice = Segment(size: Float(self.softdevice), color: .nordicFall, title: "Soft Device", shortTitle: "SD")
            let bootloader = Segment(size: Float(self.bootloader), color: .nordicLake, title: "Bootloader", shortTitle: "BL")
            return [softDevice, bootloader, application]
        }
    }
}

class DFUFirmwareSizeSchemeCell: UITableViewCell {

    @IBOutlet private var segmentedView: SegmentedView!
    @IBOutlet private var legendStackView: UIStackView!
    @IBOutlet private var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        segmentedView.layer.cornerRadius = 6
        segmentedView.layer.masksToBounds = true
    }
    
    func setFirmware(firmware: DFUFirmware) {
        legendStackView.arrangedSubviews.forEach { [weak self] v in
            self?.legendStackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        let segments = firmware.size.segments
        segments.forEach { self.legendStackView.addArrangedSubview(LegendLabel(segment: $0)) }
        segmentedView.segments = segments
        titleLabel.text = firmware.fileName ?? "Firmware"
    }
    
    
}
