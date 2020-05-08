/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
