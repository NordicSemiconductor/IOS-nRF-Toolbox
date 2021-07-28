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
import NordicDFU

class DFUFirmwareSizeSection: DFUActionSection {
    
    var firmware: DFUFirmware
    let action: () -> ()
    
    init(firmware: DFUFirmware, action: @escaping () -> ()) {
        self.firmware = firmware
        self.action = action
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        switch index {
        case 0:
            let cell = tableView.dequeueCell(ofType: DFUFirmwareSizeSchemeCell.self)
            cell.setFirmware(firmware: firmware)
            cell.selectionStyle = .none
            return cell
        case firmware.size.segments.count + 1:
            let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
            cell.textLabel?.text = "Change Distribution Package"
            return cell
        default:
            let segment = firmware.size.segments[index - 1]
            let cell = tableView.dequeueCell(ofType: NordicRightDetailTableViewCell.self)
            cell.tintColor = segment.color
            cell.textLabel?.text = segment.title
            cell.detailTextLabel?.text = ByteCountFormatter().string(fromByteCount: Int64(segment.size))
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func reset() { }
    
    var numberOfItems: Int {
        firmware.size.segments.count + 2
    }
    
    var sectionTitle: String = "Firmware Info"
    
    var id: Identifier<Section> = "DFUFirmwareSizeSection"
    
    var isHidden: Bool = false
    
    
}
