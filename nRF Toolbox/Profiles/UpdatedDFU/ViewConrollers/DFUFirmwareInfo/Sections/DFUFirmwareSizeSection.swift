//
//  DFUFirmwareSizeSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

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
            cell.textLabel?.text = "Change Destribution Package"
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
